# orchestrate_labs.py
import subprocess
import csv

def deploy_class(period_num, roster_csv_path):
    """
    Spins up isolated containers for an entire class period.
    Assigns ports sequentially (e.g., Period 1 starts at 2001, Period 2 at 2101).
    """
    base_port = 2000 + (period_num * 100)
    
    with open(roster_csv_path, mode='r') as file:
        reader = csv.DictReader(file) # Expects columns: 'student_id'
        
        for index, row in enumerate(reader):
            student = row['student_id']
            container_name = f"p{period_num}-{student}"
            assigned_port = base_port + index
            
            # Host directory paths for persistence and grading logs
            home_volume = f"/var/lab_data/{container_name}/home"
            grade_volume = f"/var/lab_data/{container_name}/grades"
            
            # Docker command to spin up the student's unique sandbox
            docker_cmd = [
                "docker", "run", "-d",
                "--name", container_name,
                "-p", f"{assigned_port}:22",
                "-v", f"{home_volume}:/home/student",
                "-v", f"{grade_volume}:/var/grading_output",
                "lab1_1-sandbox:latest"
            ]
            
            subprocess.run(docker_cmd)
            print(f"Deployed {container_name} on port {assigned_port}")

# Example Usage for your day:
# deploy_class(1, "period1_roster.csv")
# deploy_class(2, "period2_roster.csv")

