dir=`pwd`

DEPENDENCIES=./env/lib/python3.10/site-packages

function repackage_it() {
  name=$1
  cd $name
  zip -r $dir/dist/$name.zip main.py requirements.txt
  cd $dir
}

rm -rf dist
mkdir dist
repackage_it receiver
repackage_it sender
repackage_it starter
