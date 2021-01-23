import logging
import os

c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.open_browser = False
c.ServerApp.port = 8080
c.ServerApp.allow_origin_pat = '(^https://8080-dot-[0-9]+-dot-devshell\.appspot\.com$)|(^https://colab\.research\.google\.com$)|((https?://)?[0-9a-z]+-dot-datalab-vm[\-0-9a-z]*.googleusercontent.com)|((https?://)?[0-9a-z]+-dot-[\-0-9a-z]*.notebooks.googleusercontent.com)|((https?://)?[0-9a-z\-]+\.us-west1\.cloudshell)|((https?://)ssh\.cloud\.google\.com/devshell)'
c.ServerApp.allow_remote_access = True
c.ServerApp.disable_check_xsrf = False
c.ServerApp.root_dir = '/home/jovyan'

# jupyterlab-system-monitor settings
c.ServerApp.ResourceUseDisplay.mem_limit = 15032385536
c.ServerApp.ResourceUseDisplay.track_cpu_percent = True
c.ServerApp.ResourceUseDisplay.cpu_limit = 4
