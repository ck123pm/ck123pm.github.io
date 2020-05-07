check_result=`docker container ls -a|grep newblog |awk '{print $1}'`

docker exec -it "$check_result" hexo d
msg=$1
if [ -n "$msg" ]; then
   git add -A
   git commit -m"${msg}"
   git pull
   git status
   git push origin blogData
else
    echo "请添加注释再来一遍"
fi