local util = import './.github/jsonnet/index.jsonnet';
local image = 'europe-docker.pkg.dev/unicorn-985/private-images/docker-images_node20-with-libnss:v1';

local testJob = util.ghJob(
  'test-pr',
  image=image,
  useCredentials=true,
  steps=[
    util.checkoutAndYarn(ref='${{ github.event.pull_request.head.sha }}', fullClone=false),
    util.action('setup chrome', 'browser-actions/setup-chrome@latest'),
    util.step('test', './node_modules/.bin/ember test'),
  ],
  runsOn=['ubuntu-latest'],  // it's public fork. don't use private runners for public fork
);

util.workflowJavascriptPackage(testJob=testJob, branch='master')
