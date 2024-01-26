import atexit
import logging
import os
import readline
from pathlib import Path

histfile = Path(
    os.path.join(
        os.environ.get("XDG_STATE_HOME")
        or os.path.expanduser(os.path.join("~", ".local", "state")),
        "python",
        "history",
    )
)

if not os.path.exists(histfile):
    histfile.parent.mkdir(exist_ok=True)
    readline.write_history_file(histfile)

logger = logging.getLogger(__name__)
if os.environ.get("DEBUG"):
    logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())

logger.debug(f"Loading history from {histfile}")
readline.read_history_file(histfile)
H_LEN = readline.get_current_history_length()


def save_history_file():
    old_histfile = Path(os.path.join(os.path.expanduser("~"), ".python_history"))
    if os.path.exists(old_histfile):
        os.remove(old_histfile)

    readline.set_history_length(int(os.environ.get("HISTSIZE") or 2**13))

    if hasattr(readline, "append_history_file"):
        logger.debug(f"Appending history to {histfile}")
        new_h_len = readline.get_current_history_length()
        readline.append_history_file(new_h_len - H_LEN, histfile)
        return

    logger.debug(f"Writing history to {histfile}")
    readline.write_history_file(histfile)


atexit.register(save_history_file)
