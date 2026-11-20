"""Post one COMMENT review on the analyzed head with inline findings."""

import json
import os
import re
import subprocess
import sys


def added_lines(files):
    """Return GitHub-commentable new lines for findings on the changed files."""
    positions = set()
    for file in files:
        number = 0
        for row in file.get("patch", "").splitlines():
            if row.startswith("@@"):
                match = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", row)
                if match:
                    number = int(match[1])
            elif row.startswith("+"):
                positions.add((file["filename"], number))
                number += 1
            elif row.startswith(" "):
                number += 1
    return positions


def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    head = os.environ["HEAD"]
    api = ["gh", "api", f"repos/{repo}/pulls/{os.environ['PR']}"]
    result = json.loads(os.environ["REVIEW"])
    pr = json.loads(subprocess.check_output(api))
    if pr["head"]["sha"] != head or pr["draft"] or pr["state"] != "open":
        print("The pull request has moved, closed or returned to draft.")
        return
    lines = ["### Codex review", "", f"Model: {os.environ['MODEL']} · Head: {head[:12]}", ""]
    comments = []
    for issue in result["findings"]:
        path, line = issue["path"], issue["line"]
        body = f"**{issue['severity']}** {issue['body']}"
        lines.append(f"- `{path}:{line}` {body}" if line > 0 else f"- `{path}` {body}")
        if line > 0:
            comments.append({"path": path, "line": line, "side": "RIGHT", "body": body})
    if not result["findings"]:
        lines.append("No new issues found.")
    payload = {"event": "COMMENT", "commit_id": head, "body": "\n".join(lines)}
    if comments:
        pages = json.loads(subprocess.check_output(
            [*api[:-1], "--paginate", "--slurp", api[-1] + "/files?per_page=100"]
        ))
        anchors = added_lines(file for page in pages for file in page)
        comments = [c for c in comments if (c["path"], c["line"]) in anchors]
        if comments:
            payload["comments"] = comments
    api[-1] += "/reviews"
    command = [*api, "--method", "POST", "--input", "-", "--silent"]
    posted = subprocess.run(command, input=json.dumps(payload), text=True, capture_output=True)
    if posted.returncode and comments and "HTTP 422" in posted.stderr:
        # A finding can cite a context line outside the diff. Keep it in the
        # summary when GitHub rejects the inline positions of the review.
        del payload["comments"]
        subprocess.run(command, input=json.dumps(payload), text=True, check=True)
    elif posted.returncode:
        sys.exit(posted.stderr)


if __name__ == "__main__":
    main()
