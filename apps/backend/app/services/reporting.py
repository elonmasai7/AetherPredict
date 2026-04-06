from __future__ import annotations

import csv
import io
from datetime import datetime


def render_csv(rows: list[dict]) -> str:
    buffer = io.StringIO()
    if not rows:
        return ""
    writer = csv.DictWriter(buffer, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue()


def render_simple_pdf(title: str, lines: list[str]) -> bytes:
    safe_lines = [title, "", *lines, "", f"Generated {datetime.utcnow().isoformat()}Z"]
    content = "BT /F1 12 Tf 50 780 Td " + " Tj T* ".join(f"({line.replace('(', '[').replace(')', ']')})" for line in safe_lines) + " Tj ET"
    objects = [
        "1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj",
        "2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj",
        "3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj",
        f"4 0 obj << /Length {len(content)} >> stream\n{content}\nendstream endobj",
        "5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj",
    ]
    header = "%PDF-1.4\n"
    offsets: list[int] = []
    body = ""
    for obj in objects:
        offsets.append(len(header.encode()) + len(body.encode()))
        body += obj + "\n"
    xref_start = len(header.encode()) + len(body.encode())
    xref = ["xref", f"0 {len(objects) + 1}", "0000000000 65535 f "]
    xref.extend(f"{offset:010d} 00000 n " for offset in offsets)
    trailer = f"trailer << /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref_start}\n%%EOF"
    return (header + body + "\n".join(xref) + "\n" + trailer).encode()
