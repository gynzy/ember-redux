local util = import './.github/jsonnet/index.jsonnet';
local image = 'europe-docker.pkg.dev/unicorn-985/private-images/docker-images_node24-with-libnss:v1';

local testJob = util.ghJob(
  'test',
  image=image,
  useCredentials=true,
  runsOn=['ubuntu-latest'],
  steps=[
    util.pnpm.checkoutAndPnpm(
      ref='${{ github.event.pull_request.head.sha }}',
      source='github',
    ),
    util.action('setup chrome', 'browser-actions/setup-chrome@latest'),
    util.step('test', 'pnpm test'),
  ],
);

util.workflowJavascriptPackage(
  repositories=['github', 'gynzy'],
  packageManager='pnpm',
  branch='main',
  isPublicFork=true,
  testJob=testJob,
)
