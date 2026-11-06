# Fixture module: prints the DRY_RUN value it receives.
echo_help() { echo "echo: prints DRY_RUN"; }
echo_main() { echo "${DRY_RUN:-0}"; }
