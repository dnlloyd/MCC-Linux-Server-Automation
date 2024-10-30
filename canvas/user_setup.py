"""
This module is used as a helper for Linux Server automation. It fetches student info from Canvas for AWS user and 
Linux user creation. It also creates initial Linux passwords and messages users via Canvas.

Usage: 
export CANVAS_STUDENTS_FILE=<Path to store students info to>
export CANVAS_COURSE_ID=<Canvas course ID>
export CANVAS_TOKEN=<Canvas token>
export AWS_IDC_START_URL=<The AWS Identity Center start URL>
python user_setup.py
"""

import json
import os
import random
import string

import requests


TEST_MODE = False
DEBUG = False

students_file = os.environ['CANVAS_STUDENTS_FILE']
token = os.environ['CANVAS_TOKEN']
canvas_course_id = os.environ['CANVAS_COURSE_ID']
aws_identity_center_start_url = ['AWS_IDC_START_URL']
headers = {'Authorization': f'Bearer {token}'}

def generate_password():
    """Generate short, one time password"""
    length = 6
    characters = string.ascii_letters + string.digits
    password = ''.join(random.choice(characters) for i in range(length))

    return password


def send_message(canvas_student_id, context_code, subject, message):
    """Send message to student via Canvas"""
    post_data = {
        'recipients[]': canvas_student_id,
        'subject': subject,
        'body': message,
        'force_new' : True,
        'context_code': f'course_{context_code}',
    }

    response = requests.post('https://mcckc.instructure.com/api/v1/conversations', headers=headers, data=post_data, timeout=10)
    response.raise_for_status()

    if DEBUG:
        response_json = json.loads(response.content.decode())
        print(response_json)


def main():
    """Fetch student info from Canvas for user creation, create initial Linux passwords, and message users via Canvas"""
    response = requests.get(f'https://mcckc.instructure.com/api/v1/courses/{canvas_course_id}/users?per_page=50', headers=headers, timeout=10)
    response.raise_for_status()

    student_response = json.loads(response.content.decode())
    students = {}

    for student in student_response:
        password = generate_password()

        if TEST_MODE:
            if student['login_id'] == "E0759422":
                students[student['login_id']] = {
                    "full_name": student["name"],
                    "first_name": student["name"].split(" ")[0],
                    "last_name": student["name"].split(" ")[1],
                    "email": student['email'],
                    "password": password
                }

                message = f"https://d-9067d70b1d.awsapps.com/start \nUsername: {student['login_id']}"
                send_message(student['id'], canvas_course_id, "CSIS-119 AWS login link", message)

                message = f"Username: {student['login_id']}\npassword: {password}"
                send_message(student['id'], canvas_course_id, "CSIS-119 Linux server login credentials", message)
        else:
            students[student['login_id']] = {
            "full_name": student["name"],
            "first_name": student["name"].split(" ")[0],
            "last_name": student["name"].split(" ")[1],
            "email": student['email'],
            "password": password
            }

            message = f"https://d-9067d70b1d.awsapps.com/start \nUsername: {student['login_id']}"
            send_message(student['id'], canvas_course_id, "CSIS-119 AWS login link", message)

            message = f"Username: {student['login_id']}\npassword: {password}"
            send_message(student['id'], canvas_course_id, "CSIS-119 Linux server login credentials", message)


    with open(students_file, 'w', encoding="utf-8") as outfile:
        json.dump(students, outfile)

    if DEBUG:
        print(students)

    print(f"Student info has been written to: {students_file}")
    print('WARNING: Re-running this script will resend Canvas messages but the new passwords will not be updated on the Linux server')


if __name__ == "__main__":
    main()
