if [ -n "$(git status --porcelain)" ]; then
	echo "changes not commited." && exit;
fi
git submodule update
hugo --theme=hugo-theme-cactus-plus
git checkout gh-pages
git add public && git stash && rm -rf ./* && git stash pop && mv public/* ./ && rm -r public && git add -A
git status
echo -n "commit message:"
read cms
git commit -m "$cms"
echo "changes committed to gh-pages branch, push to deploy."
