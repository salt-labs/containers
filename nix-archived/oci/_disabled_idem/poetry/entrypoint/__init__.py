import subprocess

process = subprocess.Popen(
    [
        'idem'
    ],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE
)

stdout, stderr = process.communicate()

stdout, stderr
