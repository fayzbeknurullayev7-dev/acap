import asyncio
import fcntl
import json
import os
import pty
import select
import signal
import struct
import termios
import uuid
from datetime import datetime, timezone
from typing import Callable, Optional

from loguru import logger

from core.config import settings


class PtySession:
    """Manages a single PTY (pseudo-terminal) process."""

    def __init__(
        self,
        session_id: str,
        project_path: str,
        user_id: str,
        on_output: Callable[[str, str], None],   # (session_id, data)
        on_exit:   Callable[[str, int], None],    # (session_id, exit_code)
    ):
        self.session_id   = session_id
        self.project_path = project_path
        self.user_id      = user_id
        self._on_output   = on_output
        self._on_exit     = on_exit

        self.pid:      Optional[int] = None
        self.master_fd: Optional[int] = None
        self._task:    Optional[asyncio.Task] = None
        self.created_at = datetime.now(timezone.utc)
        self.last_activity = datetime.now(timezone.utc)

    def start(self):
        """Fork a PTY child process."""
        self.pid, self.master_fd = pty.fork()

        if self.pid == 0:
            # ── Child process ──────────────────────────────────────────
            os.chdir(self.project_path)
            os.environ['TERM']  = 'xterm-256color'
            os.environ['SHELL'] = settings.PTY_SHELL
            os.environ['HOME']  = os.path.expanduser('~')
            os.environ['PATH']  = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
            os.execvp(settings.PTY_SHELL, [settings.PTY_SHELL, '--login'])
        else:
            # ── Parent process ─────────────────────────────────────────
            self._set_size(settings.PTY_COLS, settings.PTY_ROWS)
            fcntl.fcntl(self.master_fd, fcntl.F_SETFL, os.O_NONBLOCK)
            logger.info(f"PTY session {self.session_id} started, pid={self.pid}")

    def _set_size(self, cols: int, rows: int):
        if self.master_fd is None:
            return
        size = struct.pack('HHHH', rows, cols, 0, 0)
        fcntl.ioctl(self.master_fd, termios.TIOCSWINSZ, size)

    async def read_loop(self):
        """Async loop to read PTY output and forward to WebSocket."""
        loop = asyncio.get_event_loop()

        while True:
            try:
                # Non-blocking check for data
                ready, _, _ = select.select([self.master_fd], [], [], 0.05)
                if not ready:
                    await asyncio.sleep(0.01)
                    continue

                data = os.read(self.master_fd, settings.OUTPUT_BUFFER_KB * 1024)
                if not data:
                    break

                self.last_activity = datetime.now(timezone.utc)
                text = data.decode('utf-8', errors='replace')
                await loop.run_in_executor(None, self._on_output, self.session_id, text)

            except OSError:
                # PTY closed
                break
            except Exception as e:
                logger.error(f"PTY read error [{self.session_id}]: {e}")
                break

        # Child exited
        exit_code = self._wait()
        self._on_exit(self.session_id, exit_code)

    def write(self, data: str):
        """Write input data to PTY."""
        if self.master_fd is None:
            return
        try:
            os.write(self.master_fd, data.encode('utf-8'))
            self.last_activity = datetime.now(timezone.utc)
        except OSError as e:
            logger.warning(f"PTY write error [{self.session_id}]: {e}")

    def resize(self, cols: int, rows: int):
        self._set_size(cols, rows)

    def kill(self):
        if self.pid:
            try:
                os.kill(self.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        if self.master_fd:
            try:
                os.close(self.master_fd)
            except OSError:
                pass
        self.pid = None
        self.master_fd = None

    def _wait(self) -> int:
        if not self.pid:
            return -1
        try:
            _, status = os.waitpid(self.pid, os.WNOHANG)
            return os.WEXITSTATUS(status) if os.WIFEXITED(status) else -1
        except ChildProcessError:
            return -1

    @property
    def is_idle(self) -> bool:
        elapsed = (datetime.now(timezone.utc) - self.last_activity).total_seconds()
        return elapsed > settings.PTY_TIMEOUT_SEC


class PtyManager:
    """Manages all active PTY sessions."""

    def __init__(self):
        self._sessions: dict[str, PtySession] = {}

    def create_session(
        self,
        project_path: str,
        user_id: str,
        on_output: Callable,
        on_exit: Callable,
    ) -> PtySession:
        session_id = str(uuid.uuid4())
        session    = PtySession(
            session_id=session_id,
            project_path=project_path,
            user_id=user_id,
            on_output=on_output,
            on_exit=on_exit,
        )
        session.start()
        self._sessions[session_id] = session
        return session

    def get_session(self, session_id: str) -> Optional[PtySession]:
        return self._sessions.get(session_id)

    def close_session(self, session_id: str):
        session = self._sessions.pop(session_id, None)
        if session:
            session.kill()
            logger.info(f"PTY session {session_id} closed")

    def get_user_sessions(self, user_id: str) -> list[PtySession]:
        return [s for s in self._sessions.values() if s.user_id == user_id]

    def cleanup_idle(self):
        idle = [sid for sid, s in self._sessions.items() if s.is_idle]
        for sid in idle:
            logger.info(f"Cleaning up idle session {sid}")
            self.close_session(sid)


pty_manager = PtyManager()
