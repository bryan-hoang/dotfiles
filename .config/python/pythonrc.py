import atexit
import os
import readline

histfile = os.path.join(
    os.path.expanduser(os.environ["XDG_STATE_HOME"]), "python", "history"
)

histfile = os.path.abspath(histfile)
_dir, _ = os.path.split(histfile)
os.makedirs(_dir, exist_ok=True)

if not os.path.exists(histfile):
    readline.add_history("import os")
    readline.write_history_file(histfile)

print("Loading history from", histfile)
readline.read_history_file(histfile)
H_LEN = readline.get_current_history_length()


def save_history_file():
    new_h_len = readline.get_current_history_length()
    readline.set_history_length(1000)
    readline.append_history_file(new_h_len - H_LEN, histfile)


atexit.register(save_history_file)
