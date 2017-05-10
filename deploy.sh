if [ -n "$(git status --porcelain)" ]; then
	echo "changes not commited." && exit;
fi
hugo --theme=hugo-theme-cactus-plus
git checkout gh-pages
echo -n "commit message:"
read cms
git add public && git stash && rm -rf ./* && git stash pop && mv public/* ./ && rm -r public && git add -A && git commit -m "$cms"

