{
  checkout(ifClause=null, fullClone=false, ref=null)::
    local with = (if fullClone then { 'fetch-depth': 0 } else {}) + (if ref != null then {'ref': ref } else {});
    $.action('Check out repository code',
      'actions/checkout@v2',
       with=with,
       ifClause=ifClause
    ),

  lint(service)::
    $.step('lint-' + service,
      './node_modules/.bin/eslint "./packages/' + service + '/{app,lib,tests,config,addon}/**/*.js" --quiet'),
  
  lintAll()::
    $.step('lint', 'yarn lint'),

  verifyGoodFences()::
    $.step('verify-good-fences', 'yarn run gf'),

  improvedAudit()::
    $.step('audit', 'yarn improved-audit'),

  verifyJsonnet(fetch_upstream=true)::
    $.ghJob('verify-jsonnet-gh-actions',
      image=$.jsonnet_bin_image,
      steps=[
        $.checkout(ref='${{ github.event.pull_request.head.sha }}'),
        $.step('remove-workflows', 'rm -f .github/workflows/*')] +
        (if fetch_upstream then [$.step('fetch latest lib-jsonnet',
              ' rm -rf .github/jsonnet/;
                mkdir .github/jsonnet/;
                cd .github;
                curl https://files.gynzy.net/lib-jsonnet/v1/jsonnet-prod.tar.gz | tar xvzf -;
              ')] else []
        )
        + [$.step('generate-workflows', 'jsonnet -m .github/workflows/ -S .github.jsonnet;'),
        $.step('git workaround', 'git config --global --add safe.directory $PWD'),
        $.step('check-jsonnet-diff', 'git diff --ignore-space-at-eol --exit-code'),
      ],
    ),

  verifyDeployJob(name, needs, url, expected_value='${{ github.event.deployment.payload.pr }}', attempts=100)::
    $.ghJob(name,
      needs=needs,
      image = $.verify_deploy_image,
      steps=[
        $.step('verify ' + name + ' deploy',
          'bash /ping.sh',
          env = {
            ATTEMPTS: attempts,
            EXPECTED_VALUE: expected_value,
            URL: url,
          }
        ),
      ],
      runsOn=['ubuntu-latest'],
    ),

  updatePRDescriptionPipeline(
    bodyTemplate,
    titleTemplate = '',
    baseBranchRegex = '[a-z\\d-_.\\\\/]+',
    headBranchRegex = '[a-z]+-\\d+',
    bodyUpdateAction = 'suffix',
    titleUpdateAction = 'prefix',
    otherOptions = {},
  )::
    $.pipeline('update-pr-description',
      event = {
        'pull_request': { types: ['opened'] },
      },
      jobs = [
        $.ghJob(
          'update-pr-description',
          steps = [
            $.action(
              'update-pr-description',
              'gynzy/pr-update-action@v2',
              with={
                'repo-token': "${{ secrets.GITHUB_TOKEN }}",
                'base-branch-regex': baseBranchRegex,
                'head-branch-regex': headBranchRegex,
                'title-template': titleTemplate,
                'body-template': bodyTemplate,
                'body-update-action': bodyUpdateAction,
                'title-update-action': titleUpdateAction,
              } + otherOptions,
            )
          ],
          useCredentials=false,
        ),
      ],
      permissions = {
        'pull-requests': 'write',
      },
    ),

  shortServiceName(name)::
    assert name != null;
    std.strReplace(std.strReplace(name, 'gynzy-', ''), 'unicorn-', ''),

  secret(secretName)::
    '${{ secrets.' + secretName + ' }}',

  pollUrlForContent(url, expectedContent, name='verify-deploy', attempts='100', interval='2000')::
    $.action(name, 'gynzy/wait-for-http-content@v1',
      with={
        url: url,
        expectedContent: expectedContent,
        attempts: attempts,
        interval: interval,
      }
    ),

  notifiyDeployFailure(channel='#dev-deployments', name='notify-failure', environment="production")::
    $.action(name, 'act10ns/slack@v1',
      with={
        status: "${{ job.status }}",
        channel: channel,
        'webhook-url': '${{ secrets.SLACK_WEBHOOK_DEPLOY_NOTIFICATION }}',
        message: "Deploy of job$ ${{ github.job }} to env: " + environment + " failed!"
      },
      ifClause='failure()',
    )
}
