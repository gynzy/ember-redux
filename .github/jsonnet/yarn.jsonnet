{
  yarn(ifClause=null, prod=false)::
    $.step(
      'yarn' + (if prod then '-prod' else ''),
      run='yarn --cache-folder .yarncache --frozen-lockfile --prefer-offline' + (if prod then ' --prod' else '') + ' || yarn --cache-folder .yarncache --frozen-lockfile --prefer-offline' + (if prod then ' --prod' else ''),
      ifClause=ifClause,
    ),

  setNpmToken(ifClause=null)::
    $.step('set npm_token', run='
cat <<EOF > .npmrc
registry=https://npm.gynzy.net/
always-auth="true"
"//npm.gynzy.net/:_authToken"="${NPM_TOKEN}"
EOF
      ',
      env={
        NPM_TOKEN: $.secret('npm_token'),
      },
      ifClause=ifClause,
    ),

  checkoutAndYarn(cacheName=null, ifClause=null, fullClone=false, ref=null, prod=false)::
    $.checkout(ifClause=ifClause, fullClone=fullClone, ref=ref) +
    $.setNpmToken(ifClause=ifClause) +
    (if cacheName == null then [] else $.fetchYarnCache(cacheName, ifClause=ifClause)) +
    $.yarn(ifClause=ifClause, prod=prod),

  fetchYarnCache(cacheName, ifClause=null):: $.step(
    'download yarn cache',
    run='echo "Downloading yarn cache && node_modules"\nwget -q -O - https://storage.googleapis.com/files-gynzy-com-test/yarn-cache/' + cacheName + '.tar.gz | tar xfz -
if [ $? -ne 0 ]; then
  # download failed. cleanup node_modules because it can contain a yarn integrity file but not have all the data as specified
  echo "Cache download failed, cleanup up caches and run yarn without cache"
  find . -type d -name \'node_modules\' | xargs rm -rf
  rm -rf .yarncache
  echo "Cleanup complete"
else
  echo "Finished downloading yarn cache && node_modules"
fi
',
    ifClause=ifClause
  ),

  updateYarnCachePipeline(cacheName, appsDir='packages', image=null, useCredentials=null)::
    $.pipeline(
      'update-yarn-cache',
      [
        $.ghJob(
          'update-yarn-cache',
          image=image,
          useCredentials=useCredentials,
          ifClause="${{ github.event.deployment.environment == 'production' || github.event.deployment.environment == 'prod' }}",
          steps=[
            $.checkout() +
            $.setNpmToken() +
            $.yarn(),
            $.action(
              'setup auth',
              'google-github-actions/auth@v0',
              with={
                credentials_json: $.secret('SERVICE_JSON'),
              },
              id='auth',
            ),
            $.action('setup-gcloud', 'google-github-actions/setup-gcloud@v0'),
            $.step('upload-yarn-cache',
              '
set -e

echo "Creating cache archive"
# v1
ls ' + appsDir + '/*/node_modules -1 -d 2>/dev/null | xargs tar -czf ' + cacheName + '.tar.gz .yarncache node_modules

echo "Upload cache"
gsutil cp ' + cacheName + '.tar.gz gs://files-gynzy-com-test/yarn-cache/' + cacheName + '.tar.gz.tmp
gsutil mv gs://files-gynzy-com-test/yarn-cache/' + cacheName + '.tar.gz.tmp gs://files-gynzy-com-test/yarn-cache/' + cacheName + '.tar.gz

echo "Upload finished"
',
            ),
          ],
        ),
      ],
      event='deployment',
    ),

  configureGoogleAuth(secret):: $.step(
    'activate google service account',
    run='printf \'%s\' "$SERVICE_JSON" > /gce.json;
          gcloud auth activate-service-account --key-file=/gce.json;
          gcloud --quiet auth configure-docker',
    env={ SERVICE_JSON: secret },
  ),

  yarnPublish(isPr=true)::
    $.step('publish',
           '
bash -c \'set -xeo pipefail;

VERSION=$(yarn version --non-interactive 2>/dev/null | grep "Current version" | grep -o -P \'[0-9a-zA-Z_.-]+$\' );
if [[ ! -z "${PR_NUMBER}" ]]; then
	echo "Setting tag/version for pr build.";
	TAG=pr-$PR_NUMBER;
	PUBLISHVERSION="$VERSION-pr$PR_NUMBER.$GITHUB_RUN_NUMBER";
elif [[ "${GITHUB_REF_TYPE}" == "tag" ]]; then
	if [[ "${GITHUB_REF_NAME}" != "${VERSION}" ]]; then
	  echo "Tag version does not match package version. They should match. Exiting";
		exit 1;
	fi
	echo "Setting tag/version for release/tag build.";
	PUBLISHVERSION=$VERSION;
	TAG="latest";
else
	exit 1
fi

yarn publish --non-interactive --no-git-tag-version --tag "$TAG" --new-version "$PUBLISHVERSION"\';
    ',
           env={} + (if isPr then { PR_NUMBER: '${{ github.event.number }}' } else {})),

}
