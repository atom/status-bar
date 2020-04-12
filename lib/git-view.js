'use babel'
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let GitView;
import _ from "underscore-plus";
import { CompositeDisposable, GitRepositoryAsync } from "atom";

export default GitView = class GitView {
  constructor() {
    this.element = document.createElement('status-bar-git');
    this.element.classList.add('git-view');

    this.createBranchArea();
    this.createCommitsArea();
    this.createStatusArea();

    this.activeItemSubscription = atom.workspace.getCenter().onDidChangeActivePaneItem(() => {
      this.subscribeToActiveItem();
    });
    this.projectPathSubscription = atom.project.onDidChangePaths(() => {
      this.subscribeToRepositories();
    });
    this.subscribeToRepositories();
    this.subscribeToActiveItem();
  }

  createBranchArea() {
    this.branchArea = document.createElement('div');
    this.branchArea.classList.add('git-branch', 'inline-block');
    this.element.appendChild(this.branchArea);
    this.element.branchArea = this.branchArea;

    const branchIcon = document.createElement('span');
    branchIcon.classList.add('icon', 'icon-git-branch');
    this.branchArea.appendChild(branchIcon);

    this.branchLabel = document.createElement('span');
    this.branchLabel.classList.add('branch-label');
    this.branchArea.appendChild(this.branchLabel);
    this.element.branchLabel = this.branchLabel;
  }

  createCommitsArea() {
    this.commitsArea = document.createElement('div');
    this.commitsArea.classList.add('git-commits', 'inline-block');
    this.element.appendChild(this.commitsArea);

    this.commitsAhead = document.createElement('span');
    this.commitsAhead.classList.add('icon', 'icon-arrow-up', 'commits-ahead-label');
    this.commitsArea.appendChild(this.commitsAhead);

    this.commitsBehind = document.createElement('span');
    this.commitsBehind.classList.add('icon', 'icon-arrow-down', 'commits-behind-label');
    this.commitsArea.appendChild(this.commitsBehind);
  }

  createStatusArea() {
    this.gitStatus = document.createElement('div');
    this.gitStatus.classList.add('git-status', 'inline-block');
    this.element.appendChild(this.gitStatus);

    this.gitStatusIcon = document.createElement('span');
    this.gitStatusIcon.classList.add('icon');
    this.gitStatus.appendChild(this.gitStatusIcon);
    this.element.gitStatusIcon = this.gitStatusIcon;
  }

  subscribeToActiveItem() {
    const activeItem = this.getActiveItem();

    if (this.savedSubscription != null) {
      this.savedSubscription.dispose();
    }
    if (activeItem && typeof activeItem.onDidSave == "function") {
        this.savedSubscription =  activeItem.onDidSave(() => this.update());
    }

    this.update();
  }

  subscribeToRepositories() {
    if (this.repositorySubscriptions != null) {
      this.repositorySubscriptions.dispose();
    }
    this.repositorySubscriptions = new CompositeDisposable;

    for (let repo of atom.project.getRepositories()) {
      if (repo != null) {
        this.repositorySubscriptions.add(repo.onDidChangeStatus(({path, status}) => {
          if (path === this.getActiveItemPath()) { this.update(); }
        })
        );
        this.repositorySubscriptions.add(repo.onDidChangeStatuses(() => {
          this.update();
        })
        );
      }
    }
  }

  destroy() {
    if (this.activeItemSubscription != null) {
      this.activeItemSubscription.dispose();
    }
    if (this.projectPathSubscription != null) {
      this.projectPathSubscription.dispose();
    }
    if (this.savedSubscription != null) {
      this.savedSubscription.dispose();
    }
    if (this.repositorySubscriptions != null) {
      this.repositorySubscriptions.dispose();
    }
    if (this.branchTooltipDisposable != null) {
      this.branchTooltipDisposable.dispose();
    }
    if (this.commitsAheadTooltipDisposable != null) {
      this.commitsAheadTooltipDisposable.dispose();
    }
    if (this.commitsBehindTooltipDisposable != null) {
      this.commitsBehindTooltipDisposable.dispose();
    }
    this.statusTooltipDisposable != null ? this.statusTooltipDisposable.dispose() : undefined;
  }

  getActiveItemPath() {
    const activeItem = this.getActiveItem();
    if (activeItem && typeof activeItem.getPath == "function") {
        return activeItem.getPath();
    }
  }

  getRepositoryForActiveItem() {
    const [rootDir] = Array.from(atom.project.relativizePath(this.getActiveItemPath()));
    const rootDirIndex = atom.project.getPaths().indexOf(rootDir);
    if (rootDirIndex >= 0) {
      return atom.project.getRepositories()[rootDirIndex];
    } else {
      for (let repo of atom.project.getRepositories()) {
        if (repo) {
          return repo;
        }
      }
    }
  }

  getActiveItem() {
    return atom.workspace.getCenter().getActivePaneItem();
  }

  update() {
    const repo = this.getRepositoryForActiveItem();
    this.updateBranchText(repo);
    this.updateAheadBehindCount(repo);
    this.updateStatusText(repo);
  }

  updateBranchText(repo) {
    if (this.showGitInformation(repo)) {
      const head = repo.getShortHead(this.getActiveItemPath());
      this.branchLabel.textContent = head;
      if (head) { this.branchArea.style.display = ''; }
      if (this.branchTooltipDisposable != null) {
        this.branchTooltipDisposable.dispose();
      }
      this.branchTooltipDisposable = atom.tooltips.add(this.branchArea, {title: `On branch ${head}`});
    } else {
      this.branchArea.style.display = 'none';
    }
  }

  showGitInformation(repo) {
    let itemPath;
    if (repo == null) { return false; }

    if ((itemPath = this.getActiveItemPath())) {
      return atom.project.contains(itemPath);
    } else {
      return (this.getActiveItem() == null);
    }
  }

  updateAheadBehindCount(repo) {
    if (!this.showGitInformation(repo)) {
      this.commitsArea.style.display = 'none';
      return;
    }

    const itemPath = this.getActiveItemPath();
    const {ahead, behind} = repo.getCachedUpstreamAheadBehindCount(itemPath);
    if (ahead > 0) {
      this.commitsAhead.textContent = ahead;
      this.commitsAhead.style.display = '';
      if (this.commitsAheadTooltipDisposable != null) {
        this.commitsAheadTooltipDisposable.dispose();
      }
      this.commitsAheadTooltipDisposable = atom.tooltips.add(this.commitsAhead, {title: `${_.pluralize(ahead, 'commit')} ahead of upstream`});
    } else {
      this.commitsAhead.style.display = 'none';
    }

    if (behind > 0) {
      this.commitsBehind.textContent = behind;
      this.commitsBehind.style.display = '';
      if (this.commitsBehindTooltipDisposable != null) {
        this.commitsBehindTooltipDisposable.dispose();
      }
      this.commitsBehindTooltipDisposable = atom.tooltips.add(this.commitsBehind, {title: `${_.pluralize(behind, 'commit')} behind upstream`});
    } else {
      this.commitsBehind.style.display = 'none';
    }

    if ((ahead > 0) || (behind > 0)) {
      this.commitsArea.style.display = '';
    } else {
      this.commitsArea.style.display = 'none';
    }
  }

  clearStatus() {
    this.gitStatusIcon.classList.remove('icon-diff-modified', 'status-modified', 'icon-diff-added', 'status-added', 'icon-diff-ignored', 'status-ignored');
  }

  updateAsNewFile() {
    this.clearStatus();

    this.gitStatusIcon.classList.add('icon-diff-added', 'status-added');
    const textEditor = atom.workspace.getActiveTextEditor();
    if (textEditor) {
      this.gitStatusIcon.textContent = `+${textEditor.getLineCount()}`;
      this.updateTooltipText(`${_.pluralize(textEditor.getLineCount(), 'line')} in this new file not yet committed`);
    } else {
      this.gitStatusIcon.textContent = '';
      this.updateTooltipText();
    }

    this.gitStatus.style.display = '';
  }

  updateAsModifiedFile(repo, path) {
    const stats = repo.getDiffStats(path);
    this.clearStatus();

    this.gitStatusIcon.classList.add('icon-diff-modified', 'status-modified');
    if (stats.added && stats.deleted) {
      this.gitStatusIcon.textContent = `+${stats.added}, -${stats.deleted}`;
      this.updateTooltipText(`${_.pluralize(stats.added, 'line')} added and ${_.pluralize(stats.deleted, 'line')} deleted in this file not yet committed`);
    } else if (stats.added) {
      this.gitStatusIcon.textContent = `+${stats.added}`;
      this.updateTooltipText(`${_.pluralize(stats.added, 'line')} added to this file not yet committed`);
    } else if (stats.deleted) {
      this.gitStatusIcon.textContent = `-${stats.deleted}`;
      this.updateTooltipText(`${_.pluralize(stats.deleted, 'line')} deleted from this file not yet committed`);
    } else {
      this.gitStatusIcon.textContent = '';
      this.updateTooltipText();
    }

    this.gitStatus.style.display = '';
  }

  updateAsIgnoredFile() {
    this.clearStatus();

    this.gitStatusIcon.classList.add('icon-diff-ignored',  'status-ignored');
    this.gitStatusIcon.textContent = '';
    this.gitStatus.style.display = '';
    this.updateTooltipText("File is ignored by git");
  }

  updateTooltipText(text) {
    if (this.statusTooltipDisposable != null) {
      this.statusTooltipDisposable.dispose();
    }
    if (text) {
      this.statusTooltipDisposable = atom.tooltips.add(this.gitStatusIcon, {title: text});
    }
  }

  updateStatusText(repo) {
    const hideStatus = () => {
      this.clearStatus();
      this.gitStatus.style.display = 'none';
    };

    const itemPath = this.getActiveItemPath();
    if (this.showGitInformation(repo) && (itemPath != null)) {

      let repoCachedPathStatus = repo.getCachedPathStatus(itemPath);
      const status = repoCachedPathStatus != null ? repoCachedPathStatus : 0;

      if (repo.isStatusNew(status)) {
        this.updateAsNewFile();
        return;
      }

      if (repo.isStatusModified(status)) {
        this.updateAsModifiedFile(repo, itemPath);
        return;
      }

      if (repo.isPathIgnored(itemPath)) {
        this.updateAsIgnoredFile();
        return;
      } else {
        hideStatus();
        return;
      }
    } else {
      hideStatus();
      return;
    }
  }
};
