import json
import sys


def main() -> None:
    arguments = json.load(sys.stdin)
    a = float(arguments["a"])
    b = float(arguments["b"])
    json.dump({"sum": a + b}, sys.stdout)


if __name__ == "__main__":
    main()