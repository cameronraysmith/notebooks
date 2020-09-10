import logging
import os

c.NotebookApp.token = ''
c.NotebookApp.password = ''
c.NotebookApp.open_browser = False
c.NotebookApp.port = 8080
c.NotebookApp.allow_origin_pat = '(^https://8080-dot-[0-9]+-dot-devshell\.appspot\.com$)|(^https://colab\.research\.google\.com$)|((https?://)?[0-9a-z]+-dot-datalab-vm[\-0-9a-z]*.googleusercontent.com)|((https?://)?[0-9a-z]+-dot-[\-0-9a-z]*.notebooks.googleusercontent.com)|((https?://)?[0-9a-z\-]+\.us-west1\.cloudshell)|((https?://)ssh\.cloud\.google\.com/devshell)'
c.NotebookApp.allow_remote_access = True
c.NotebookApp.disable_check_xsrf = False
c.NotebookApp.notebook_dir = '/home/jovyan'
