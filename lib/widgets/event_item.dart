import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:git_touch/models/github.dart';
import 'package:git_touch/models/theme.dart';
import 'package:git_touch/widgets/action_button.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'avatar.dart';
import '../widgets/link.dart';
import '../utils/utils.dart';

class EventItem extends StatelessWidget {
  final GithubEvent event;

  EventItem(this.event);

  TextSpan _buildLinkSpan(ThemeModel theme, String text) {
    return TextSpan(
      text: text,
      style: TextStyle(
        color: theme.palette.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  TextSpan _buildRepo(ThemeModel theme) =>
      _buildLinkSpan(theme, event.repo.name);

  Iterable<ActionItem> _getUserActions(List<String> users) {
    // Remove duplicates
    return users.toSet().map((user) {
      return ActionItem.user(user);
    });
  }

  Widget _buildItem({
    @required BuildContext context,
    @required List<InlineSpan> spans,
    String detail,
    Widget detailWidget,
    IconData iconData = Octicons.octoface,
    String url,
    List<ActionItem> actionItems,
  }) {
    final theme = Provider.of<ThemeModel>(context);

    if (detailWidget == null && detail != null) {
      detailWidget =
          Text(detail.trim(), overflow: TextOverflow.ellipsis, maxLines: 5);
    }

    return Link(
      url: url,
      child: Container(
        padding: CommonStyle.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Link(
                  url: '/' + event.actor.login,
                  child: Avatar.medium(url: event.actor.avatarUrl),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: join(SizedBox(height: 8), [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.palette.text,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            _buildLinkSpan(theme, event.actor.login),
                            ...spans,
                          ],
                        ),
                      ),
                      if (detailWidget != null)
                        DefaultTextStyle(
                          style: TextStyle(
                              color: theme.palette.text, fontSize: 14),
                          child: detailWidget,
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(iconData,
                              color: theme.palette.tertiaryText, size: 14),
                          SizedBox(width: 4),
                          Text(timeago.format(DateTime.parse(event.createdAt)),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.palette.tertiaryText,
                              )),
                          Expanded(child: Container()),
                          GestureDetector(
                            child: Icon(Icons.more_horiz),
                            onTap: () {
                              theme.showActions(context, actionItems);
                            },
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultItem(BuildContext context) {
    final theme = Provider.of<ThemeModel>(context);
    return _buildItem(
      context: context,
      spans: [
        TextSpan(
          text: ' ' + event.type,
          style: TextStyle(color: theme.palette.primary),
        )
      ],
      iconData: Octicons.octoface,
      detail: 'Woops, ${event.type} not implemented yet',
    );
  }

  @override
  build(BuildContext context) {
    final theme = Provider.of<ThemeModel>(context);

    // all events types here:
    // https://developer.github.com/v3/activity/events/types/#event-types--payloads
    switch (event.type) {
      case 'CheckRunEvent':
      case 'CheckSuiteEvent':
      case 'CommitCommentEvent':
      case 'ContentReferenceEvent':
      case 'CreateEvent':
      case 'DeleteEvent':
      case 'DeploymentEvent':
      case 'DeploymentStatusEvent':
      case 'DownloadEvent':
      case 'FollowEvent':
        // TODO:
        return _buildDefaultItem(context);
      case 'ForkEvent':
        final forkeeOwner = event.payload['forkee']['owner']['login'] as String;
        final forkeeName = event.payload['forkee']['name'] as String;
        return _buildItem(
          context: context,
          spans: [
            TextSpan(text: ' forked '),
            _buildLinkSpan(theme, '$forkeeOwner/$forkeeName'),
            TextSpan(text: ' from '),
            _buildRepo(theme),
          ],
          iconData: Octicons.repo_forked,
          url: '/$forkeeOwner/$forkeeName',
          actionItems: [
            ..._getUserActions([event.actor.login, forkeeOwner]),
            ActionItem.repository(forkeeOwner, forkeeName),
            ActionItem.repository(event.repoOwner, event.repoName),
          ],
        );
      case 'ForkApplyEvent':
      case 'GitHubAppAuthorizationEvent':
      case 'GistEvent':
      case 'GollumEvent':
      case 'InstallationEvent':
      case 'InstallationRepositoriesEvent':
        // TODO:
        return _buildDefaultItem(context);
      case 'IssueCommentEvent':
        final isPullRequest = event.payload['issue']['pull_request'] != null;
        final resource = isPullRequest ? 'pull request' : 'issue';
        final number = event.payload['issue']['number'] as int;

        return _buildItem(
          context: context,
          spans: [
            TextSpan(text: ' commented on $resource '),
            _buildLinkSpan(theme, '#$number'),
            TextSpan(text: ' at '),
            _buildRepo(theme),
            // TextSpan(text: event.payload['comment']['body'])
          ],
          detail: event.payload['comment']['body'],
          iconData: Octicons.comment_discussion,
          url:
              '/${event.repoOwner}/${event.repoName}/${isPullRequest ? 'pulls' : 'issues'}/$number',
          actionItems: [
            ..._getUserActions([event.actor.login, event.repoOwner]),
            ActionItem.pullRequest(event.repoOwner, event.repoName, number),
          ],
        );
      case 'IssuesEvent':
        final action = event.payload['action'];
        final number = event.payload['issue']['number'] as int;

        return _buildItem(
          context: context,
          spans: [
            TextSpan(text: ' $action issue '),
            _buildLinkSpan(theme, '#$number'),
            TextSpan(text: ' at '),
            _buildRepo(theme),
          ],
          iconData: Octicons.issue_opened,
          detail: event.payload['issue']['title'],
          url: '/${event.repoOwner}/${event.repoName}/issues/$number',
          actionItems: [
            ..._getUserActions([event.actor.login, event.repoOwner]),
            ActionItem.repository(event.repoOwner, event.repoName),
            ActionItem.issue(event.repoOwner, event.repoName, number),
          ],
        );
      case 'LabelEvent':
      case 'MarketplacePurchaseEvent':
      case 'MemberEvent':
      case 'MembershipEvent':
      case 'MilestoneEvent':
      case 'OrganizationEvent':
      case 'OrgBlockEvent':
      case 'PageBuildEvent':
      case 'ProjectCardEvent':
      case 'ProjectColumnEvent':
      case 'ProjectEvent':
      case 'PublicEvent':
        // TODO:
        return _buildDefaultItem(context);
      case 'PullRequestEvent':
        final action = event.payload['action'];
        final number = event.payload['pull_request']['number'] as int;

        return _buildItem(
          context: context,
          spans: [
            TextSpan(text: ' $action pull request '),
            _buildLinkSpan(theme, '#$number'),
            TextSpan(text: ' at '),
            _buildRepo(theme),
          ],
          iconData: Octicons.git_pull_request,
          detail: event.payload['pull_request']['title'],
          url: '/${event.repoOwner}/${event.repoName}/pulls/$number',
          actionItems: [
            ..._getUserActions([event.actor.login, event.repoOwner]),
            ActionItem.repository(event.repoOwner, event.repoName),
            ActionItem.pullRequest(event.repoOwner, event.repoName, number),
          ],
        );
      case 'PullRequestReviewEvent':
        // TODO:
        return _buildDefaultItem(context);
      case 'PullRequestReviewCommentEvent':
        final number = event.payload['pull_request']['number'] as int;

        return _buildItem(
          context: context,
          spans: [
            TextSpan(text: ' reviewed pull request '),
            _buildLinkSpan(theme, '#$number'),
            TextSpan(text: ' at '),
            _buildRepo(theme),
          ],
          detail: event.payload['comment']['body'],
          url: '/${event.repoOwner}/${event.repoName}/pulls/$number',
          actionItems: [
            ..._getUserActions([event.actor.login, event.repoOwner]),
            ActionItem.repository(event.repoOwner, event.repoName),
            ActionItem.pullRequest(event.repoOwner, event.repoName, number),
          ],
        );
      case 'PushEvent':
        final ref = event.payload['ref'] as String;
        final commits = event.payload['commits'] as List;

        return _buildItem(
          context: context,
          spans: [
            TextSpan(text: ' pushed to '),
            WidgetSpan(
              child: PrimerBranchName(ref.replaceFirst('refs/heads/', '')),
            ),
            TextSpan(text: ' at '),
            _buildRepo(theme)
          ],
          iconData: Octicons.repo_push,
          detailWidget: Column(
            children: commits.map((commit) {
              return Row(
                children: <Widget>[
                  Text(
                    (commit['sha'] as String).substring(0, 7),
                    style: TextStyle(
                      color: theme.palette.primary,
                      fontSize: 13,
                      fontFamily: CommonStyle.monospace,
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      commit['message'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )
                ],
              );
            }).toList(),
          ),
          url:
              'https://github.com/${event.repoOwner}/${event.repoName}/compare/${event.payload['before']}...${event.payload['head']}',
          actionItems: [
            ..._getUserActions([event.actor.login, event.repoOwner]),
            ActionItem.repository(event.repoOwner, event.repoName),
          ],
        );
      case 'ReleaseEvent':
      case 'RepositoryEvent':
      case 'RepositoryImportEvent':
      case 'RepositoryVulnerabilityAlertEvent':
      case 'SecurityAdvisoryEvent':
      case 'StatusEvent':
      case 'TeamEvent':
      case 'TeamAddEvent':
        // TODO:
        return _buildDefaultItem(context);
      case 'WatchEvent':
        return _buildItem(
          context: context,
          spans: [TextSpan(text: ' starred '), _buildRepo(theme)],
          iconData: Octicons.star,
          url: '/${event.repoOwner}/${event.repoName}',
          actionItems: [
            ..._getUserActions([event.actor.login, event.repoOwner]),
            ActionItem.repository(event.repoOwner, event.repoName),
          ],
        );
      default:
        return _buildDefaultItem(context);
    }
  }
}
