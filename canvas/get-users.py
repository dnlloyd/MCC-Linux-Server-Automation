import requests
import json
import base64
import gnupg
import os
# import re

students_file = os.environ['CANVAS_STUDENTS_FILE']
student_passwords_file = os.environ['CANVAS_STUDENT_PASSWORDS_FILE']
student_passwords_file_plain_text = os.environ['CANVAS_STUDENT_PASSWORDS_FILE_PLAIN_TEXT']
manual_user_provision_script = os.environ['MANUAL_USER_PROVISION_SCRIPT']
token = os.environ['CANVAS_TOKEN']
canvas_course_id = os.environ['CANVAS_COURSE_ID']
aws_account_id = os.environ['AWS_ACCOUNT_ID']
mode = os.environ['C_MODE']

headers = {'Authorization': f'Bearer {token}'}

def write_students_to_file():
  response = requests.get(f'https://mcckc.instructure.com/api/v1/courses/{canvas_course_id}/users?per_page=50', headers=headers)

  if response.status_code == 200:
    student_info = json.loads(response.content.decode())

    student_emails = {}

    print(f'Writing student data to file: {students_file}\n---')
    print('Canvas student ID: Student name (MCC student ID)\n---')
    for student in student_info:
      student_emails[student['login_id']] = student['email']
      print(f'{student["id"]}: {student["name"]} ({student["login_id"]})')

    with open(students_file, 'w') as outfile:
      json.dump(student_emails, outfile)

  else:
    print(response.status_code)
    print(f'{response}')


def send_message(id, context_code, subject, message):
  post_data = {
    'recipients[]': id,
    'subject': subject,
    'body': message,
    'force_new' : True,
    'context_code': f'course_{context_code}',
    # 'scope': 'unread'
  }
  
  response = requests.post('https://mcckc.instructure.com/api/v1/conversations', headers=headers, data=post_data)
  
  print(f'Response code: {response.status_code}')
  # response_json = json.loads(response.content.decode())
  # print(response_json)


def decode_password(encoded_password):
  decoded_password = base64.b64decode(encoded_password)
  gpg = gnupg.GPG()
  password = gpg.decrypt(decoded_password)
  
  return password


def get_user(student_id):
  response = requests.get(f'https://mcckc.instructure.com/api/v1/courses/{canvas_course_id}/users?search_term={student_id}', headers=headers)

  print(f'Looking up student: {student_id}')
  # print(response.status_code)
  if response.status_code != 200:
    print('Unable to find student')
  else:
    student_info = json.loads(response.content.decode())
    print(f'Found student: {student_info[0]["name"]}')
    
    return student_info[0]["id"] 


################### Main ###################
# Write student info to students_file
if mode == "write":
  write_students_to_file()
  print('')

# Decrypt passwords and send to students
if mode == "send":
  passwords_file = open(student_passwords_file)
  student_passwords = json.load(passwords_file)

  passwords_plain_text = {}
  invalid_passwords = {}
  manual_provision_script = manual_user_provision_script

  for student in student_passwords:
    student_id = student
    encrypted_password = student_passwords[student]
    password = decode_password(encrypted_password)

    send_passwords = True
    if send_passwords:
      # lookup student by student ID (e.g. S1234567) and return Canvas ID
      canvas_id = get_user(student_id)

      print(f'Sending password to: {student_id} ({canvas_id})')
      message = f'https://{aws_account_id}.signin.aws.amazon.com/console \nIAM user name: {student_id} \npassword: {password}'
      print(message)
      send_message(canvas_id, canvas_course_id, "Linux server credentials", message)
      print('')

    translate_table = str.maketrans({"$": r"\$"})

    pass_plain_text = str(password)
    pass_plain_text_trans = pass_plain_text.translate(translate_table)

    ########## Debug
    # print(pass_plain_text_escaped)
    # print(pass_plain_text)
    # os.system(f'echo {pass_plain_text_escaped_trans}')
    # print('')

    if "!" in pass_plain_text_trans:
      invalid_passwords[student_id] = pass_plain_text_trans
    else:
      passwords_plain_text[student_id] = pass_plain_text_trans

  passwords_plain_text_json = json.dumps(passwords_plain_text)
  with open(f'{student_passwords_file_plain_text}', 'w') as outfile:
    outfile.write(passwords_plain_text_json)

  if len(invalid_passwords) != 0:
    print('WARNING: Some users were created with passwords that will not provision correctly. They need to be manually provisioned.')
    print(f'Writing commands to :{manual_provision_script}\n')
    with open(manual_provision_script, "w") as outfile:    
      for student in invalid_passwords:
        student_id = student
        password = invalid_passwords[student]

        new_pass = password.replace("!", "\"'!'\"")
        print(f'useradd {student_id}\necho "{new_pass}" | passwd {student_id} --stdin')
        outfile.write(f'useradd {student_id}\necho "{new_pass}" | passwd {student_id} --stdin\n')
