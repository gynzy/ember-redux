local util = import './.github/jsonnet/index.jsonnet';
local image = 'eu.gcr.io/unicorn-985/docker-images_node14-with-libnss:deploy-5893c6fca68ea35a0a51e855d5a3cb7082ef39fa';

util.pipeline(
  'test-pr',
  [
    util.ghJob(
      'test-pr',
      image=image,
      useCredentials=true,
      steps=[
        util.checkoutAndYarn(ref='${{ github.event.pull_request.head.sha }}', fullClone=false),
        util.action('setup chrome', 'browser-actions/setup-chrome@latest'),
        util.step('test', './node_modules/.bin/ember test'),
        util.yarnPublish(isPr=true),
      ],
      runsOn=['ubuntu-latest'],  // it's public fork. don't use private runners for public fork
    ),
  ],
) +
util.pipeline(
  'publish-tag',
  [
    util.ghJob(
      'publish',
      image=image,
      useCredentials=true,
      steps=[
        util.checkoutAndYarn(ref='${{ github.sha }}', fullClone=false),
        util.yarnPublish(isPr=false),
      ],
      runsOn=['ubuntu-latest'],  // it's public fork. don't use private runners for public fork
    ),
  ],
  event={
    push: { tags: ['*'] },
  },
)
