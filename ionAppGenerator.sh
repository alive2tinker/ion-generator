#!/bin/bash

#check the appName exists
if [ -z "$1" ]
then
      exit 1
fi

ionic start $1 tabs --type=vue --package-id=com.app-builder-$1 --capacitor --no-interactive &

wait $!

#change directories and run npm command
cd ./$1 && 
npm uninstall --save typescript @types/jest @typescript-eslint/eslint-plugin @typescript-eslint/parser @vue/cli-plugin-typescript @vue/eslint-config-typescript &&
i=0 &&
while read line
do
   array[$i]="$line"
   (( i++ )) 
done < <(find ./src -type f -name "*.ts") &&

for file in ${array[*]}
do
    if [[ $file == *"shims-vue"* ]]; then
        rm -rf $file
    else
    mv -- "$file" "${file%.ts}.js"
    fi
done &&

i=0
while read line
do
   vueArray[$i]="$line"
   (( i++ )) 
done < <(find ./src -type f -name "*.vue") &&

for file in ${vueArray[*]}
do
    sed -e "s/lang=\"ts\"//g" -i.backup $file
done &&

eslintFile=$(find . -maxdepth 1 -type f -name ".eslintrc.js") &&

sed -e "s/'\@vue\/typescript\/recommended'//g" -i.backup $eslintFile &&
sed -e "s/'\@typescript-eslint\/no-explicit-any': 'off',//g" -i.backup $eslintFile &&

routerFile=$(find ./src/router -type f -name "index.js") &&

sed -e "s/import { RouteRecordRaw } from 'vue-router';//g" -i.backup $routerFile &&
sed -e "s/: Array<RouteRecordRaw>//g" -i.backup $routerFile &&

echo "this is the current working directory: " . $PWD &&
ionic capacitor add ios &&
ionic capacitor add android &&
echo "y" | vue add vuex@next &&
#add tailwind
npm install -D tailwindcss postcss autoprefixer &&
printf "const autoprefixer = require('autoprefixer');\nconst tailwindcss = require('tailwindcss');\n\nmodule.exports = {\n\tplugins: [\n\t\ttailwindcss,\n\t\tautoprefixer,\n\t],\n};" >> postcss.config.js &&
mkdir -p src/assets/css &&
printf "@tailwind base;\n@tailwind components;\n@tailwind utilities;" >> src/assets/css/app.css &&
npx tailwind init
# need to change this line when on ubuntu
awk 'NR==25 {print "import './assets/styles/tailwind.css';"}1' src/main.js


