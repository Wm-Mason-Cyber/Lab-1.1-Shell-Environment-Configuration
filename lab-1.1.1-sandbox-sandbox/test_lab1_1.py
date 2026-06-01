import os
import subprocess
import pytest

# Helper function to run commands inside the student's actual Bash environment
def run_in_bash(command, login_shell=True):
    shell_flag = "-lc" if login_shell else "-c"   # Claude recommmended "-lc" for login shell
    # Sourcing profile/bashrc files by simulating an interactive/login shell
    process = subprocess.Popen(
        ["/bin/bash", shell_flag, command],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    stdout, stderr = process.communicate()
    return process.returncode, stdout.strip(), stderr.strip()

## ------------------------------------------------------------------
## [cite_start]TESTS (These align with the 40% Automated Testing Framework) [cite: 101]
## ------------------------------------------------------------------

def test_custom_path_extension():
    """
    Verify the student successfully appended a custom directory to their PATH.
    For example: Ensuring a local 'bin' directory is prioritized.
    """
    # Run a command to print the environment's PATH variable
    rc, stdout, stderr = run_in_bash("echo $PATH")
    
    assert rc == 0, "Shell failed to execute properly."
    # [cite_start]Check if they successfully manipulated environmental execution parameters [cite: 38]
    assert "/custom/lab/bin" in stdout, (
        "High-entropy error: Your custom directory '/custom/lab/bin' "
        "was not found in your system's PATH variable."
    )

def test_local_environment_flag():
    """
    [cite_start]Verify that a specific local configuration flag or variable is set[cite: 38].
    """
    rc, stdout, stderr = run_in_bash("echo $CYBER_DEFENDER_ROLE")
    
    assert rc == 0
    assert stdout == "Level_1_Engineer", (
        "The local environment variable '$CYBER_DEFENDER_ROLE' is either "
        "missing or set to an incorrect scope."
    )

def test_shell_behavior_scope():
    """
    [cite_start]Verify understanding of subshell vs. parent shell scopes[cite: 38].
    Ensures a variable is exported globally, not just locally.
    """
    # Simulating a subshell call to see if the variable persists across scopes
    rc, stdout, stderr = run_in_bash("bash -c 'echo $MY_EXPORTED_VAR'")
    
    assert rc == 0
    assert stdout != "", (
        "The variable was found in the parent scope but did not persist "
        "into the subshell scope. Did you forget to use 'export'?"
    )

def pytest_terminal_summary(terminalreporter, exitstatus, config):
    """
    A execution hook that automatically saves the results to the host 
    mounted volume immediately when the student runs 'submit-lab'.
    """
    passed = len(terminalreporter.stats.get('passed', []))
    failed = len(terminalreporter.stats.get('failed', []))
    total = passed + failed
    score = (passed / total) * 100 if total > 0 else 0
    
    import json
    report = {
        "status": "Completed",
        "passed_assertions": passed,
        "failed_assertions": failed,
        "grade": score
    }
    
    # This writes out to the directory mapped to the host server
    try:
        with open("/var/grading_output/results.json", "w") as f:
            json.dump(report, f)
    except Exception:
        pass # Prevent script crash if directory isn't mounted correctly
