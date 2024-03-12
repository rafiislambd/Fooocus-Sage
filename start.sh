#!/bin/bash

# Set this variable to true to install to the temporary folder, or to false to have the installation in permanent storage.
install_in_temp_dir=true

if [ ! -d "UxFooocus" ]
then
  git clone https://github.com/rafiislambd/UxFooocus.git
fi
cd UxFooocus
git pull
if [ "$install_in_temp_dir" = true ]
then
  echo "Installation folder: /tmp/UxFooocus"
  if [ ! -L ~/.conda/envs/UxFooocus ]
  then
    echo "removing ~/.conda/envs/UxFooocus"
    rm -rf ~/.conda/envs/UxFooocus
    rmdir ~/.conda/envs/UxFooocus
    ln -s /tmp/UxFooocus ~/.conda/envs/
  fi
else
  echo "Installation folder: ~/.conda/envs/UxFooocus"
  if [ -L ~/.conda/envs/UxFooocus ]
  then
    rm ~/.conda/envs/UxFooocus
  fi
fi
eval "$(conda shell.bash hook)"
if [ ! -d ~/.conda/envs/UxFooocus ]
then 
    echo ".conda/envs/UxFooocus is not a directory or does not exist"
fi
if [ "$install_in_temp_dir" = true ] && [ ! -d /tmp/UxFooocus ] || [ "$install_in_temp_dir" = false ] && [ ! -d ~/.conda/envs/UxFooocus ]
then
    echo "Installing"
    if [ "$install_in_temp_dir" = true ] && [ ! -d /tmp/UxFooocus ]
    then
        mkdir /tmp/UxFooocus
    fi
    conda env create -f environment.yaml
    conda activate UxFooocus
    pwd
    ls
    pip install -r requirements_versions.txt
    pip install torch torchvision --force-reinstall --index-url https://download.pytorch.org/whl/cu117
    pip install pyngrok
    conda install glib -y
    rm -rf ~/.cache/pip
fi

# Because the file manager in Sagemaker Studio Lab ignores the folder called "checkpoints"
# we need to move checkpoint files into a folder with a different name
current_folder=$(pwd)
model_folder=${current_folder}/models/checkpoints-real-folder
if [ ! -e config.txt ]
then
  json_data="{ \"path_checkpoints\": \"$model_folder\" }"
  echo "$json_data" > config.txt
  echo "JSON file created: config.txt"
else
  echo "Updating config.txt to use checkpoints-real-folder"
  jq --arg new_value "$model_folder" '.path_checkpoints = $new_value' config.txt > config_tmp.txt && mv config_tmp.txt config.txt
fi

# If the checkpoints folder exists, move it to the new checkpoints-real-folder
if [ ! -L models/checkpoints ]
then
    mv models/checkpoints models/checkpoints-real-folder
    ln -s models/checkpoints-real-folder models/checkpoints
fi

conda activate UxFooocus
cd ..
if [ $# -eq 0 ]
then
  python start-ngrok.py 
elif [ $1 = "reset" ]
then
  python start-ngrok.py --reset 
fi
