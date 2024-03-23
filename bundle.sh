cd ../daemon
pnpm build

cd ../panel-instance
pnpm build

cd ../bundler
rm -rf ./dist
mkdir ./dist
cp setup.sh ./dist
cp -r ../daemon/dist ./dist/api
cp -r ../panel-instance/.next/standalone ./dist/web
cp -r ../panel-instance/.next/static ./dist/web/.next/static
cp -r ../panel-instance/prisma ./dist/web/prisma

tar -czf panel.tar.gz -C dist .
mv panel.tar.gz dist