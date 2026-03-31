{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.custom.git;
  git-reword = pkgs.writeShellApplication {
    name = "git-reword";
    text = ''
      if [ -z "$1" ];
      then
          echo "No SHA provided. Usage: \"git reword <SHA>\"";
          exit 1;
      fi;
      if [ "$(git rev-parse "$1")" == "$(git rev-parse HEAD)" ];
      then
          echo "$1 is the current commit on this branch.  Use \"git commit --amend\" to reword the current commit.";
          exit 1;
      fi;
      git merge-base --is-ancestor "$1" HEAD;
      ANCESTRY=$?;
      if [ $ANCESTRY -eq 1 ];
      then
          echo "SHA is not an ancestor of HEAD.";
          exit 1;
      elif [ $ANCESTRY -eq 0 ];
      then
          git stash;
          START=$(git rev-parse --abbrev-ref HEAD);
          git branch savepoint;
          git reset --hard "$1";
          git commit --amend;
          git rebase -p --onto "$START" "$1" savepoint;
          git checkout "$START";
          git merge savepoint;
          git branch -d savepoint;
          git stash pop;
      else
          exit 2;
      fi
    '';
  };
in {
  home.packages = [
    pkgs.codex
    git-reword
    pkgs.delta
    pkgs.lazygit
  ];

  programs = {
    gh.enable = true;
    git = {
      enable = true;
      # GPG SIGNING KEY
      signing = lib.mkIf cfg.enable {
        signByDefault = true;
        key = cfg.git-keyid;
      };
      settings = {
        user.name = "Kirirou Otomichi";
        user.email = "souonchouryuu@proton.me";
        init = {defaultBranch = "master";};
        push.autoSetupRemote = true;
        # remote.origin.push = "HEAD";
        # branch = {
        #   master = {merge = "refs/heads/master";};
        # };
        core = {
          pager = "delta";
        };
        interactive = {
          diffFilter = "delta --color-only";
        };
        delta = {
          navigate = true;
          light = false;
          # side-by-side = true;
        };
        merge = {
          conflictstyle = "diff3";
        };
        format = {
          pretty = "format:%C(yellow)%h%Creset -%C(red)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset";
        };
        diff = {
          # tool = "nvim -d";
          # guitool = "code";
          tool = "hx";
          guitool = "hx";
          colorMoved = "default";
        };
        pull = {rebase = true;};
        push = {default = "simple";};

        aliases = {reword = "!sh git-reword";};
      };
    };
  };

  # extra git functions
  custom.shell.packages = {
    # create a new branch and push it to origin
    gbc = ''
      git branch "$1"
      git checkout "$1"
    '';
    # delete a remote branch
    grd = ''
      git branch -D "$1"
      git push origin --delete "$1"
    '';
    # searches git history, can never remember this stupid thing
    # 2nd argument is target path and subsequent arguments are passed through
    gsearch = ''git log -S"$1" -- "\${"2:-."}" "$*"[2,-1]'';
  };

  home.shellAliases = {
    ghx = "hx $(git diff --name-only HEAD)";
    lg = "lazygit";
    gaa = "git --no-pager  add --all";
    gb = "git --no-pager  branch";
    gbtr = "git --no-pager  bisect reset";
    gcm = "git commit -m";
    gcaam = "gaa && gcam";
    gcam = "git --no-pager  commit --amend";
    gco = "git --no-pager  checkout";
    gdc = "git --no-pager  diff --cached";
    gdi = "git --no-pager  diff";
    gl = "git --no-pager  pull";
    glg = "git --no-pager  log";
    gm = "git --no-pager  merge";
    gp = "git --no-pager  push";
    gpf = "git --no-pager  push --force";
    glc = ''gl origin "$(git --no-pager  rev-parse --abbrev-ref HEAD)"'';
    gpc = ''gp origin "$(git --no-pager  rev-parse --abbrev-ref HEAD)"'';
    groot = "cd $(git --no-pager  rev-parse - -show-toplevel)";
    grh = "git --no-pager  reset --hard";
    gri = "git --no-pager  rebase --interactive";
    gst = "git --no-pager  status -s -b && echo && git --no-pager  log | head -n 1";
    gsub = "git --no-pager  submodule update --init --recursive";
    # access git --no-pager hub page for the repo we are currently in
    github = "open \`git --no-pager  remote -v | grep git --no-pager hub.com | grep fetch | head -1 | awk '{print $2}' | sed 's/git --no-pager :/http:/git --no-pager '\`";
    # cleanup leftover files from merges
    mergeclean = "find . -type f -name '*.orig' -exec rm -f {} \;";
  };

  custom.persist = {
    home.directories = [
      ".config/systemd"
      ".codex"
    ];
  };
}
