const call_api_with_retry_logic = require('./api.js');

const MAX_WAITING_TIME = 900;

async function create_issues(github_context, findings_per_committer) {
    const max_retries = 5;
    const default_delay = 5;
    const secondary_rate_limit_delay_base = 60;

    for (const committer in findings_per_committer) {
        try {
            const issue = await create_issue_for_committer(github_context, committer, findings_per_committer[committer], max_retries, default_delay, secondary_rate_limit_delay_base);
            await add_label_to_issue(github_context, issue, max_retries, default_delay, secondary_rate_limit_delay_base);
            await assign_issue_to_committer(github_context, committer, issue, max_retries, default_delay, secondary_rate_limit_delay_base);
        } catch (error) {
            console.error(`Failed to process committer ${committer}: ${error.message}`);
            if (error.response) {
                const retry_after = error.response.headers['retry-after'];
                const rate_limit_remaining = error.response.headers['x-ratelimit-remaining'];
                const rate_limit_reset = error.response.headers['x-ratelimit-reset'];
                if (error.response && error.response.status === 403 && ((rate_limit_remaining === '0' && (rate_limit_reset - Math.floor(Date.now()/1000)) > MAX_WAITING_TIME) || (retry_after && int(retry_after) > MAX_WAITING_TIME))) {
                throw error;
                }
            }
        }
    }
}

async function create_issue_for_committer(github_context, committer, commits, max_retries, default_delay, secondary_rate_limit_delay_base) {
    console.log(`Creating issue for committer: ${committer}`);

    const DEFAULT_VALUE = "N/A";
    const FINDINGS_PER_COMMIT = Object.entries(commits).map(([id, findings], _) => {
        const LIST_OF_FINDINGS = findings.map((entry, index) => {
        const detector = entry.DetectorName || DEFAULT_VALUE;
        const { file, line } = entry.SourceMetadata?.Data?.Git ?? {};
        const author = committer ? `[${committer}](${github_context.server_url}/${committer})` : DEFAULT_VALUE;
        const file_link = file ? `[${file}](${github_context.server_url}/${github_context.scanned_repository_owner}/${github_context.scanned_repository_name}/blob/${id}/${ encodeURI(file) }?plain=1#L${ line })` : DEFAULT_VALUE;

        return `> **FINDING ${index + 1}**\n`
                + `> &nbsp;&nbsp; **Type**\n&nbsp;&nbsp; ${detector}\n`
                + `> &nbsp;&nbsp;\n`
                + `> &nbsp;&nbsp; **Author**\n&nbsp;&nbsp; ${author}\n`
                + `> &nbsp;&nbsp;\n`
                + `> &nbsp;&nbsp; **File**\n&nbsp;&nbsp; ${file_link}\n\n`;
        });

        return `**COMMIT ${id.substring(0, 7)}**\n` + LIST_OF_FINDINGS.join("");
    }).join('<br />\n\n');

    const number_of_commits_containing_secrets = Object.keys(commits).length;
    const total_number_of_secrets = Object.values(commits).map(findings => findings.length).reduce((a, b) => a + b, 0);

    const issue = `# ⚠️ WARNING: SECRET${total_number_of_secrets > 1 ? 'S' : ''} PUSHED TO MAIN BRANCH
### ${ total_number_of_secrets } secret${total_number_of_secrets > 1 ? 's have' : ' has'} been found in ${ number_of_commits_containing_secrets } commit${ number_of_commits_containing_secrets > 1 ? 's' : ''}.

<br/><br/>

## FINDINGS
${FINDINGS_PER_COMMIT}

Please note that the detector considers all secrets found in the commit${ number_of_commits_containing_secrets > 1 ? 's' : ''}, even if they have been pushed earlier.

<br/>

You can find more information in the workflow run that generated this report:\\
${github_context.server_url}/${github_context.secrets_finder_repository}/actions/runs/${github_context.run_id}

<br/><br/>

## REMEDIATION PROCEDURE
- You **MUST** rotate the credentials that were stored in plain text. Assume they have already been compromised.
- You **MUST** move the new credentials to an approved secrets management service and pattern.
- You **SHOULD** clear the plaintext secrets from Git history.

<br/><br/>

To clean-up your Git history, you can use the following guidance:
- [Removing Sensitive Data - GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

<br/><br/>

You can also find more information about how to rotate your secrets here:
https://howtorotate.com/docs/introduction/getting-started/`

    const { data } = await call_api_with_retry_logic(() => github_context.api.issues.create({
        owner: github_context.scanned_repository_owner,
        repo: github_context.scanned_repository_name,
        title: `⚠️ Secret${total_number_of_secrets > 1 ? 's' : ''} pushed to main branch (${ number_of_commits_containing_secrets } commit${ number_of_commits_containing_secrets > 1 ? 's' : ''} affected)`,
        body: issue
    }), max_retries, default_delay, secondary_rate_limit_delay_base);

    console.log(`New issue created in repository: ${ data.html_url }`);
    return data.number;
}

async function add_label_to_issue(github_context, issue, max_retries, default_delay, secondary_rate_limit_delay_base) {
    console.log(`Adding label to issue: ${issue}`)
    await call_api_with_retry_logic(() => github_context.api.issues.addLabels({
        owner: github_context.scanned_repository_owner,
        repo: github_context.scanned_repository_name,
        issue_number: issue,
        labels: ['leaked-secrets']
    }), max_retries, default_delay, secondary_rate_limit_delay_base);
}

async function assign_issue_to_committer(github_context, committer, issue, max_retries, default_delay, secondary_rate_limit_delay_base) {
    console.log(`Assigning issue to committer: ${committer}`);
    await call_api_with_retry_logic(() =>  github_context.api.issues.addAssignees({
        owner: github_context.scanned_repository_owner,
        repo: github_context.scanned_repository_name,
        issue_number: issue,
        assignees: [committer]
    }), max_retries, default_delay, secondary_rate_limit_delay_base);
}

module.exports = create_issues;
