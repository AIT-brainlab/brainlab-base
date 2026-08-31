"""
AIT Brainlab - RFC 1179 LPD Print Protocol Client
Handles communication with CSIM Print Server (banyan.cs.ait.ac.th:515)
"""

import socket
import time
import logging

logger = logging.getLogger("web-print.lpd")

class LPDClient:
    def __init__(self, host: str = "192.41.170.5", port: int = 515, timeout: float = 15.0):
        self.host = host
        self.port = port
        self.timeout = timeout

    def check_queue(self, queue: str, long_format: bool = False) -> str:
        """Query queue status via RFC 1179 short (\x03) or long (\x04) command."""
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(self.timeout)
        try:
            s.connect((self.host, self.port))
            cmd_code = b"\x04" if long_format else b"\x03"
            s.sendall(f"{cmd_code.decode()}{queue}\n".encode("ascii"))
            resp = b""
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                resp += chunk
            return resp.decode("utf-8", errors="replace").strip()
        finally:
            s.close()

    def submit_job(
        self,
        queue: str,
        user: str,
        job_title: str,
        payload: bytes,
        is_postscript: bool = True
    ) -> str:
        """
        Submit a print job to the specified queue via RFC 1179.
        P<username> binds the job to CSIM student account for automated quota accounting.
        """
        job_id = f"{int(time.time()) % 900 + 100:03d}"
        cf_name = f"cfA{job_id}brainlab"
        df_name = f"dfA{job_id}brainlab"
        file_format_code = "l" if is_postscript else "f"

        # Build RFC 1179 Control File
        control_lines = [
            "Hbrainlab",
            f"P{user}",
            f"J{job_title}",
            f"{file_format_code}{df_name}",
            f"U{df_name}",
            f"N{job_title}.ps" if is_postscript else f"N{job_title}.pdf",
        ]
        control_data = "\n".join(control_lines).encode("ascii") + b"\n"

        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(self.timeout)
        s.connect((self.host, self.port))

        try:
            # 1. Request Queue (Command 2)
            s.sendall(f"\x02{queue}\n".encode("ascii"))
            ack = s.recv(1)
            if ack != b"\x00":
                raise RuntimeError(f"Print queue '{queue}' rejected job request with code {ack}")

            # 2. Send Control File Header and Content
            s.sendall(f"\x02{len(control_data)} {cf_name}\n".encode("ascii"))
            ack = s.recv(1)
            if ack != b"\x00":
                raise RuntimeError(f"Control file header rejected with code {ack}")

            s.sendall(control_data + b"\x00")
            ack = s.recv(1)
            if ack != b"\x00":
                raise RuntimeError(f"Control file payload rejected with code {ack}")

            # 3. Send Data File Header and Payload
            s.sendall(f"\x03{len(payload)} {df_name}\n".encode("ascii"))
            ack = s.recv(1)
            if ack != b"\x00":
                raise RuntimeError(f"Data file header rejected with code {ack}")

            s.sendall(payload + b"\x00")
            ack = s.recv(1)
            if ack != b"\x00":
                raise RuntimeError(f"Data file payload rejected with code {ack}")

            logger.info(f"Successfully submitted job {job_id} for user {user} to queue {queue}")
            return job_id
        finally:
            s.close()
