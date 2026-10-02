{...}: {
  programs = {
    yt-dlp = {
      enable = true;
      settings = {
        add-metadata = true;
        no-mtime = true;
        # format = "best[ext=mp4]";
        sponsorblock-mark = "all";
        output = "%(title)s.%(ext)s";

        # pull session cookies from the live librewolf profile so
        # members-only content is accessible (yt-dlp handles the sqlite
        # lock gracefully even while the browser is running)
        cookies-from-browser = "firefox:/home/rot/.librewolf/rot";

        # post-live/members-only VODs ("Post-Live Manifestless mode") need
        # a PO token; without a token provider configured, yt-dlp silently
        # drops those formats and reports a misleading "live event has
        # ended" error. This keeps them instead of dropping them.
        extractor-args = "youtube:formats=missing_pot";
      };
    };
  };

  home.shellAliases = {
    yt = "yt-dlp";
    ytdl = "cd ~/Downloads && yt-dlp -a ~/Desktop/yt.txt";
    ytaudio = "yt --audio-format mp3 --extract-audio --concurrent-fragments 16";
    ytsub = "yt --write-auto-sub --sub-lang='en,eng' --convert-subs srt";
    ytplaylist = "yt --output '%(playlist_index)d - %(title)s.%(ext)s'";
  };
}
