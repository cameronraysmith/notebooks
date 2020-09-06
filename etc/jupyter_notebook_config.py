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

BASE_PATH = '/opt/deeplearning/metadata/'

def read_from_file(path):
  with open(path, 'r') as file:
    return file.read().replace('\n', '')

def get_env_name():
  return read_from_file(os.path.join(BASE_PATH, 'env_version'))

def get_env_uri():
  return read_from_file(os.path.join(BASE_PATH, 'env_uri'))

def metadata_env_pre_save(model, **kwargs):
  try:
    # only run on notebooks
    if model['type'] != 'notebook':
      return
    # only run on nbformat v4 or later
    if model['content']['nbformat'] < 4:
      return

    model['content']['metadata']['environment'] = {
      'type': 'gcloud',
      'name': get_env_name(),
      'uri': get_env_uri()
    }
  except Exception as e:
    logging.error("Failed to enrich the Notebook with metadata: {}".format(e))

c.FileContentsManager.pre_save_hook = metadata_env_pre_save

c.NotebookApp.notebook_dir = '/home/jovyan'