{

    Unit PlaylistClass

    One of the Basic-Units - The Playlist

    ---------------------------------------------------------------
    Nemp - Noch ein Mp3-Player
    Copyright (C) 2005-2019, Daniel Gaussmann
    http://www.gausi.de
    mail@gausi.de
    ---------------------------------------------------------------
    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin St, Fifth Floor, Boston, MA 02110, USA

    See license.txt for more information

    ---------------------------------------------------------------
}

unit PlaylistClass;

interface

uses Windows, Forms, Contnrs, SysUtils,  VirtualTrees, IniFiles, Classes, 
    Dialogs, MMSystem, oneinst, math, RatingCtrls,
    Hilfsfunktionen, Nemp_ConstantsAndTypes,

    NempAudioFiles, AudioFileHelper, PlayerClass,
    gnuGettext, Nemp_RessourceStrings, System.UITypes, System.Types,

    MainFormHelper, CoverHelper;

type
  DWORD = cardinal;

  TPreBookInsertMode = (pb_Beginning, pb_End);

  TIndexArray = Array of Array of Integer;

  TNempPlaylist = Class
    private
      fDauer: Int64;                      // Duration of the Playlist in seconds
      fPlayingFile: TPlaylistFile;        // the current Audiofile
      fBackupFile : TPlaylistFile;        // if we delete the playingfile from the playlist, we store a copy of it here
      fPlayingIndex: Integer;             // ... its index in the list
      fPlayingNode: PVirtualNode;         // ... and its node in the Treeview
      fActiveCueNode: PVirtualNode;       // ... the active cuenode

      fPlayingFileUserInput: Boolean;     // True, after the user slides/paused/... the current audiofile.
                                          // Then the file should (depending on settings) not be deleted after playback
      fWiedergabeMode: Integer;           // One after the other, Random, ...
      fAutoMix: Boolean;                  // Mix playlist after the last title
      fJumpToNextCueOnNextClick: Boolean; // Jump only to next cue on "Next"
      fRepeatCueOnRepeatTitle: Boolean;   // repeat the current entry in cuesheet wehn "repeat title" is selected
      fShowHintsInPlaylist: Boolean;
      fPlayCounter: Integer;              // used for a "better random" selection

      fVST: TVirtualStringTree;           // the Playlist-VirtualStringTree
      fInsertNode: PVirtualNode;          // InsertNode/-Index: used for insertion of Files
      fInsertIndex: Integer;              //    (e.g. on DropFiles)

      fErrorCount: Integer;               // Stop "nextfile" after one cycle if all files in the playlist could not be found
      fFirstAction: Boolean;              // used for inserting files (ProcessBufferStringlist). On Nemp-Start the playback should bes started.
                                          // see "AutoPlayNewTitle"


      fInterruptedPlayPosition: Double;   // the Position in the track that was played just before the
                                          // user played a title directly from the library
      fInterruptedFile : TAudioFile;      // The track itself
      fRememberInterruptedPlayPosition: Boolean; // Use this position and start playback of the track there

      fLastEditedAudioFile: TAudioFile;   // the last edited AudioFile when manually sorting the PrebookList by keypress
      fLastKeypressTick: Int64;           // TickCount when the last keypress occured

      fFileSearchCounter: Integer;        // used during a search for new files to display the progress

      // PrebookList: Stores the prebooked AudioFiles,
      // i.e. the files that are marked as "play next"
      PrebookList: TObjectList;

      /// History: When playing a new File, the file played before this file is added to the historylist
      /// and fCurrentHistoryFile points to this last played file.
      ///  GetNext/GetPrevious-Index Call "UpdateHistory" first
      ///     There is checked, whether we are currently "browsing in the history" or leaving it
      ///     (in this case the last played file ist added at the end/at the beginning of the history list)
      /// After this, GetNext/GetPreviousIndex will get the new index through the history (if needed)
      ///  or get a "New" index
      fCurrentHistoryFile: TAudioFile;
      HistoryList: TObjectList;

      fLastHighlightedSearchResultNode: PVirtualNode;

      // for  weighted random
      fUseWeightedRNG: Boolean;
      // first column : "RNG value" which is significant for the Random value
      // second column: actual index of the file in the playlist
      // size: Length(Playlist) x 2, but not all fields are necessarily filled,
      //       as some files in the playlist may have no entry in this array
      //       (meaning: probability to play this file is 0
      //        ... well, almost, as it could be played in backup-mode)
      fWeightedRandomIndices: TIndexArray;
      // The maximum of the values in the first column of the array
      fMaxWeightedValue: Integer;
      fMaxWeightedIndex: Integer;
      // Flag whether the playlist has been changed and a re-init of fWeightedRandomIndices is necessary
      fPlaylistHasChanged: Boolean;

      // (new 4.11) ok, we'll get a mixture of SendMessages and Events by that, but
      // it's working, wo why not. maybe change the code to events anyway later ...
      fOnCueChanged: TNotifyEvent;

      function fGetPreBookCount: Integer;

      procedure SetInsertNode(Value: PVirtualNode);
      function GetAnAudioFile: TPlaylistFile;
      function GetNextAudioFileIndex: Integer;
      function GetPrevAudioFileIndex: Integer;

      function GetNodeWithPlayingFile: PVirtualNode;
      Procedure ScrollToPlayingNode;

      procedure AddCueListNodes(aAudioFile: TAudioFile; aNode: PVirtualNode);
      function GetActiveCueNode(aIndex: Integer): PVirtualNode;
      function GetCount: Integer;

      function GetPlayingIndex: Integer;

      // Kapselungen der entsprechenden Player-Routinen
      // bei den Settern zus�tzlich Cue-Zeug-Handling dabei.
      function GetTime: Double;
      procedure SetTime(Value: Double);
      function GetProgress: Double;
      procedure SetProgress(Value: Double);

      // UpdateHistory
      // called from GetNext- GetPrevAudioFileIndex
      // Inserts (if needed) currentfile at the end of the Historylist
      procedure UpdateHistory(Backwards: Boolean = False);

      // for  weighted random
      procedure RebuildWeighedArray;
      procedure SetUseWeightedRNG(aValue: Boolean);

      function GetRandomPlaylistIndex: Integer;


    public
      Playlist: TObjectlist;              // the list with the audiofiles
      Player: TNempPlayer;                // the player-object

      // Some settings for the playlist, stored in the Ini-File
      AutoPlayOnStart: Boolean;     // begin playback when Nemp starts
      SavePositionInTrack: Boolean; // save current position in track and restore it on next start
      PositionInTrack: Integer;
      AutoPlayNewTitle: Boolean;    // Play new title when the user selects "Enqueue in Nemp" in the explorer (and Nemp is not running, yet)
      AutoPlayEnqueuedTitle: Boolean; // PLay the enqueued track (even if Nemp is already running)
      // AutoSave: Boolean;            // Save Playlist every 5 minutes
      AutoScan: Boolean;            // Scan files with Mp3fileUtils
      AutoDelete: Boolean;                  // Delete File after playback
          DisableAutoDeleteAtUserInput: Boolean;
      BassHandlePlaylist: Boolean;      // let the bass.dll handle webstream-playlists
      RandomRepeat: Integer;   // 0..100% - which part of the Playlist should be played before a song is selected "randomly" again?

      // default-action when the user doubleclick an item in the medialibrary
      DefaultAction: Integer;
      // default-action when the user clicks "Add current Headphone-title to playlist"
      HeadSetAction: Integer;
      AutoStopHeadsetSwitchTab: Boolean;
      AutoStopHeadsetAddToPlayist: Boolean;



      TNA_PlaylistCount: Integer; // number of files displayed in the TNA-menu

      YMouseDown: Integer;      // Needed for dragging inside the playlist
      AcceptInput: Boolean;     // Block inputs after a successful beginning of playback for a short time.
                                // Multimediakeys seems to do some weird things otherwise

      MainWindowHandle: DWord;  // The Handle to the Nemp main window

      ST_Ordnerlist: TStringList; // Joblist for SearchTools
      InitialDialogFolder: String;

      CurrentSearchDir: String;

      Status: Integer;

      LastCommandWasPlay: Boolean;      // some vars needed for Explorer-stuff
      ProcessingBufferlist: Boolean;    //like "play/enqueue in Nemp"
      BufferStringList: TStringList;

      // The weights for files with rating from (0?- ) 0.5 - 5 stars
      RNGWeights: Array[0..10] of Integer;

      property Dauer: Int64 read fDauer;
      property Count: Integer read GetCount;

      property Time: Double read GetTime write SetTime;             // Do some Cue-Stuff here!
      property Progress: Double read GetProgress write SetProgress;

      property PlayingFile: TPlaylistFile read fPlayingFile;
      property PlayingIndex: Integer read GetPlayingIndex write fplayingIndex;
      property PlayingNode: PVirtualNode read fPlayingNode;
      property ActiveCueNode: PVirtualNode read fActiveCueNode;
      property PlayingFileUserInput: Boolean read fPlayingFileUserInput write fPlayingFileUserInput;
      property WiedergabeMode: Integer read fWiedergabeMode write fWiedergabeMode;
      property AutoMix: Boolean read fAutoMix write fAutoMix;
      property JumpToNextCueOnNextClick: Boolean read fJumpToNextCueOnNextClick write fJumpToNextCueOnNextClick;
      property RepeatCueOnRepeatTitle: Boolean read fRepeatCueOnRepeatTitle write fRepeatCueOnRepeatTitle;
      property RememberInterruptedPlayPosition: Boolean read fRememberInterruptedPlayPosition write fRememberInterruptedPlayPosition;

      property ShowHintsInPlaylist: Boolean read fShowHintsInPlaylist write fShowHintsInPlaylist;

      property PlayCounter: Integer read fPlayCounter;
      property VST: TVirtualStringTree read fVST write fVST;
      property OnCueChanged: TNotifyEvent read fOnCueChanged write fOnCueChanged;

      property InsertNode: PVirtualNode read fInsertNode write SetInsertNode;
      property InsertIndex: Integer read fInsertIndex;
      property PrebookCount: Integer read fGetPreBookCount;
      property FileSearchCounter: Integer read fFileSearchCounter write fFileSearchCounter;

      property LastHighlightedSearchResultNode: PVirtualNode read fLastHighlightedSearchResultNode;
      property UseWeightedRNG: Boolean read fUseWeightedRNG write SetUseWeightedRNG;
      property PlaylistHasChanged: Boolean read fPlaylistHasChanged write fPlaylistHasChanged;

      constructor Create;
      destructor Destroy; override;

      procedure LoadFromIni(Ini: TMemIniFile);
      procedure WriteToIni(Ini: TMemIniFile);

      // the most important methods: Play, Playnext, ...
      procedure Play(aIndex: Integer; aInterval: Integer; Startplay: Boolean; Startpos: Double = 0);
      procedure PlayBibFile(aFile: TAudioFile; aInterval: Integer);

      procedure PlayHeadsetFile(aFile: TAudioFile; aInterval: Integer; aPosition: Double);

      procedure PlayNextFile(aUserinput: Boolean = False);
      procedure PlayNext(aUserinput: Boolean = False);
      procedure PlayPrevious(aUserinput: Boolean = False);
      procedure PlayPreviousFile(aUserinput: Boolean = False);
      procedure PlayFocussed(aSelection: PVirtualNode = Nil);
      procedure PlayAgain(ForcePlay: Boolean = False);
      procedure Pause;
      procedure Stop;

      procedure DeleteMarkedFiles;  // Delete selected files
      procedure ClearPlaylist(StopPlayer: Boolean = True);      // Delete whole playlist
      procedure DeleteDeadFiles;    // Delete dead (non existing) files
      procedure RemovePlayingFile;  // Remove the current file from the list
      procedure RemoveFileFromHistory(aFile: TAudioFile);
      procedure RepairPlaylist(NewDriveMask: DWord); // repair the playlist when a new drive is connected
                                                     // NewDriveMask is a Bitmask as in DEV_BROADCAST_VOLUME

      //// Some GUI-Stuff
      // Get the InsertNode from current playing position
      // Note: The PlayingNode can be NIL, so this is a little bit more complicated. ;-)
      procedure GetInsertNodeFromPlayPosition;
      procedure FillPlaylistView;   // Fill the playist-Tree
      // Set CueNode and invalidate TreeView
      procedure ActualizeCue;
      // Get Audiodata from the current selected Node and repaint it
      // used e.g. in OnChange of the TreeView
      procedure ActualizeNode(aNode: pVirtualNode; ReloadDataFromFile: Boolean);
      procedure UpdatePlayListHeader(aVST: TVirtualStringTree; Anzahl: Integer; Dauer: Int64);
      function ShowPlayListSummary: Int64;

      //// Sorting the playlist
      procedure ReInitPlaylist;     // correct the NodeIndex and stuff after a sorting of the playlist
      procedure Sort(Compare: TListSortCompare);
      Procedure ReverseSortOrder;
      Procedure Mix;

      // adding files into the playlist
      // return value: the new node in the treeeview. Used for scrolling to this node
      function AddFileToPlaylist(aAudiofileName: UnicodeString; aCueName: UnicodeString = ''):PVirtualNode; overload;
      function AddFileToPlaylistWebServer(aAudiofile: TAudioFile; aCueName: UnicodeString = ''): TAudioFile;
      function InsertFileToPlayList(aAudiofileName: UnicodeString; aCueName: UnicodeString = ''):PVirtualNode; overload;
      function AddFileToPlaylist(Audiofile: TAudioFile; aCueName: UnicodeString = ''):PVirtualNode; overload;
      function InsertFileToPlayList(Audiofile: TAudioFile; aCueName: UnicodeString = ''):PVirtualNode; overload;
      procedure ProcessBufferStringlist;

      // adding a node to the PrebookList.
      // (not an Audiofile, so we can use this method directly from the Playlist-VST
      //  and after adding a file from the library to the playlist)
      procedure AddNodeToPrebookList(aNode: PVirtualnode);
      procedure ReIndexPrebookedFiles;
      procedure SetNewPrebookIndex(aFile: TAudioFile; NewIndex: Integer);
      procedure ProcessKeypress(aDigit: Byte; aNode: PVirtualNode);
      // Adding/removing selected Nodes form the PrebookList
      // not used any more. Too confusing
      // procedure AddSelectedNodesToPreBookList(Mode: TPreBookInsertMode);
      // procedure RemoveSelectedNodesFromPreBookList;

      function SuggestSaveLocation(out Directory: String; out Filename: String): Boolean;
      // load/save playlist
      procedure LoadFromFile(aFilename: UnicodeString);
      procedure SaveToFile(aFilename: UnicodeString; Silent: Boolean = True);
      // copy it from Winamp
      // procedure GetFromWinamp; No. Not any more. *g*

      // The user wants us something todo => Set ErrorCount to 0
      procedure UserInput;

      // Reinit Bass-Engine. Needed sometimes after suspending the system.
      procedure RepairBassEngine(StartPlay: Boolean);

      // when the user change the rating of a audiofile-object, it should be
      // changed in the whole playlist. (It could be multiply times in the playlist!)
      procedure UnifyRating(aFilename: String; aRating: Byte; aCounter: Integer);

      procedure CollectFilesWithSameFilename(aFilename: String; Target: TObjectList);

      // Search the Playlist for an ID. Used by Nemp Webserver
      // The links in the html-code will contain these IDs, so they will be valid
      // until the "real" Nemp-User deletes a file from the playlist.
      function GetPlaylistIndex(aID: Int64): Integer;
      function SwapFiles(a, b: Integer): Boolean;   // a and b must be siblings!!
      procedure DeleteAFile(aIdx: Integer); // delete a file (for WebServer)

      procedure ResortVotedFile(aFile: TAudioFile; aIndex: Cardinal);

      procedure ClearSearch(complete: Boolean = False);
      procedure SearchAll(aString: String); 
      procedure Search(aString: String; SearchNext: Boolean = False);

  end;

implementation

uses NempMainUnit, spectrum_vis, BibSearchClass;

var tid      : Cardinal;

procedure APM(TimerID, Msg: Uint; dwUser, dw1, dw2: DWORD); pascal;
begin
  SendMessage(dwUser, WM_PlayerAcceptInput, 0, 0);
end;


{
    --------------------------------------------------------
    Create, Destroy
    --------------------------------------------------------
}
constructor TNempPlaylist.Create;
begin
  inherited create;
  Playlist := TObjectList.Create;
  ST_Ordnerlist := TStringList.Create;
  PrebookList := TObjectList.Create(False);
  HistoryList := TObjectList.Create(False);
  fCurrentHistoryFile := Nil;
  fPlayingFile := Nil;
  fBackupFile := TPlayListFile.Create;
  AcceptInput := True;
  Status := 0;
  BufferStringList := TStringList.Create;
  ProcessingBufferlist := False;
  fFirstAction := True;
  fLastHighlightedSearchResultNode := Nil;

  //for i := 0 to 10 do
  //    RNGWeights[i] := 1;

  //tmp
  {
  self.fUseWeightedRNG := false;
  RNGWeights[0]  := 0; // unused
  RNGWeights[1]  := 0; // 0.5
  RNGWeights[2]  := 0; // 1
  RNGWeights[3]  := 1;
  RNGWeights[4]  := 2;
  RNGWeights[5]  := 4;
  RNGWeights[6]  := 7;
  RNGWeights[7]  := 12;
  RNGWeights[8]  := 20;
  RNGWeights[9]  := 35;
  RNGWeights[10] := 60;
  }
end;

destructor TNempPlaylist.Destroy;
begin
  HistoryList.Free;
  PrebookList.Free;
  Playlist.Free;
  ST_Ordnerlist.Free;
  BufferStringList.Free;
  fBackupFile.Free;
  inherited Destroy;
end;

{
    --------------------------------------------------------
    Load/Save Inifile
    --------------------------------------------------------
}
procedure TNempPlaylist.LoadFromIni(Ini: TMemIniFile);
begin
  DefaultAction         := ini.ReadInteger('Playlist','DefaultAction',0);
  HeadSetAction         := ini.ReadInteger('Playlist','HeadSetAction',0);
  AutoStopHeadsetSwitchTab       := ini.ReadBool('Playlist','AutoStopHeadset',True);
  AutoStopHeadsetAddToPlayist    := ini.ReadBool('Playlist','AutoStopHeadsetAddToPlayist',False);

  WiedergabeMode        := ini.ReadInteger('Playlist','WiedergabeModus',0);
  AutoScan              := ini.ReadBool('Playlist','AutoScan', True);
  AutoPlayOnStart       := ini.ReadBool('Playlist','AutoPlayOnStart', True);
  AutoPlayNewTitle      := ini.ReadBool('Playlist','AutoPlayNewTitle', True);
  AutoPlayEnqueuedTitle := ini.ReadBool('Playlist','AutoPlayEnqueuedTitle', False);
  // AutoSave              := ini.ReadBool('Playlist','AutoSave', True);
  AutoDelete            := ini.ReadBool('Playlist','AutoDelete', False);
  DisableAutoDeleteAtUserInput    := ini.ReadBool('Playlist','DisableAutoDeleteAtUserInput', True);
  fAutoMix                        := ini.ReadBool('Playlist','AutoMix', False);
  fJumpToNextCueOnNextClick       := Ini.ReadBool('Playlist', 'JumpToNextCueOnNextClick', True);
  fRepeatCueOnRepeatTitle         := Ini.ReadBool('Playlist', 'RepeatCueOnRepeatTitle', True);
  fRememberInterruptedPlayPosition:= Ini.ReadBool('Playlist', 'RememberInterruptedPlayPosition', True);
  fShowHintsInPlaylist  := Ini.ReadBool('Playlist', 'ShowHintsInPlaylist', True);
  RandomRepeat          := Ini.ReadInteger('Playlist', 'RandomRepeat', 25);
  TNA_PlaylistCount     := ini.ReadInteger('Playlist','TNA_PlaylistCount',30);
  fPlayingIndex         := ini.ReadInteger('Playlist','IndexinList',0);
  SavePositionInTrack   := ini.ReadBool('Playlist', 'SavePositionInTrack', True);
  PositionInTrack       := ini.ReadInteger('Playlist', 'PositionInTrack', 0);
  BassHandlePlaylist    := Ini.ReadBool('Playlist', 'BassHandlePlaylist', True);
  InitialDialogFolder   := Ini.ReadString('Playlist', 'InitialDialogFolder', '');


  fUseWeightedRNG := ini.ReadBool   ('Playlist', 'UseWeightedRNG', False);
  RNGWeights[1]   := ini.ReadInteger('Playlist', 'RNGWeights05', 0  );
  RNGWeights[2]   := ini.ReadInteger('Playlist', 'RNGWeights10', 0  );
  RNGWeights[3]   := ini.ReadInteger('Playlist', 'RNGWeights15', 1  );
  RNGWeights[4]   := ini.ReadInteger('Playlist', 'RNGWeights20', 2  );
  RNGWeights[5]   := ini.ReadInteger('Playlist', 'RNGWeights25', 4  );
  RNGWeights[6]   := ini.ReadInteger('Playlist', 'RNGWeights30', 7  );
  RNGWeights[7]   := ini.ReadInteger('Playlist', 'RNGWeights35', 12 );
  RNGWeights[8]   := ini.ReadInteger('Playlist', 'RNGWeights40', 20 );
  RNGWeights[9]   := ini.ReadInteger('Playlist', 'RNGWeights45', 35 );
  RNGWeights[10]  := ini.ReadInteger('Playlist', 'RNGWeights50', 60 );
end;

procedure TNempPlaylist.WriteToIni(Ini: TMemIniFile);
var idx: Integer;
begin
  ini.WriteInteger('Playlist','DefaultAction', DefaultAction);
  ini.WriteInteger('Playlist','HeadSetAction',HeadSetAction);
  ini.WriteBool('Playlist','AutoStopHeadset',AutoStopHeadsetSwitchTab);
  ini.WriteBool('Playlist','AutoStopHeadsetAddToPlayist',AutoStopHeadsetAddToPlayist);

  ini.WriteInteger('Playlist','WiedergabeModus',WiedergabeMode);
  ini.WriteInteger('Playlist','TNA_PlaylistCount',TNA_PlaylistCount);
  idx := fPlayingIndex;
  ini.WriteInteger('Playlist','IndexinList',idx);
  ini.WriteBool('Playlist', 'SavePositionInTrack', SavePositionInTrack);

  if (assigned(fPlayingFile)) and (idx = PlayList.IndexOf(fPlayingFile)) then
      ini.WriteInteger('Playlist', 'PositionInTrack', Round(Player.Time))
  else
  // this should be the case when we play a bibfile right now
      ini.WriteInteger('Playlist', 'PositionInTrack', Round(fInterruptedPlayPosition));

  ini.WriteBool('Playlist','AutoScan', AutoScan);
  ini.WriteBool('Playlist','AutoPlayOnStart', AutoPlayOnStart);
  ini.WriteBool('Playlist','AutoPlayNewTitle', AutoPlayNewTitle);
  ini.WriteBool('Playlist','AutoPlayEnqueuedTitle', AutoPlayEnqueuedTitle);

  Ini.WriteBool('Playlist','AutoDelete', AutoDelete);
  ini.WriteBool('Playlist','DisableAutoDeleteAtUserInput', DisableAutoDeleteAtUserInput);

  Ini.WriteBool('Playlist','AutoMix', fAutoMix);
  Ini.WriteBool('Playlist', 'JumpToNextCueOnNextClick', fJumpToNextCueOnNextClick);
  Ini.WriteBool('Playlist', 'RepeatCueOnRepeatTitle', fRepeatCueOnRepeatTitle);
  Ini.WriteBool('Playlist', 'RememberInterruptedPlayPosition', fRememberInterruptedPlayPosition);

  Ini.WriteBool('Playlist', 'ShowHintsInPlaylist', fShowHintsInPlaylist);
  Ini.WriteInteger('Playlist', 'RandomRepeat', RandomRepeat);
  Ini.WriteBool('Playlist', 'BassHandlePlaylist', BassHandlePlaylist);
  Ini.WriteString('Playlist', 'InitialDialogFolder', InitialDialogFolder);

  ini.WriteBool   ('Playlist', 'UseWeightedRNG', fUseWeightedRNG);
  ini.WriteInteger('Playlist', 'RNGWeights05', RNGWeights[1]  );
  ini.WriteInteger('Playlist', 'RNGWeights10', RNGWeights[2]  );
  ini.WriteInteger('Playlist', 'RNGWeights15', RNGWeights[3]  );
  ini.WriteInteger('Playlist', 'RNGWeights20', RNGWeights[4]  );
  ini.WriteInteger('Playlist', 'RNGWeights25', RNGWeights[5]  );
  ini.WriteInteger('Playlist', 'RNGWeights30', RNGWeights[6]  );
  ini.WriteInteger('Playlist', 'RNGWeights35', RNGWeights[7]  );
  ini.WriteInteger('Playlist', 'RNGWeights40', RNGWeights[8]  );
  ini.WriteInteger('Playlist', 'RNGWeights45', RNGWeights[9]  );
  ini.WriteInteger('Playlist', 'RNGWeights50', RNGWeights[10] );

end;


{
    --------------------------------------------------------
    main methods. Play, Playnext, ...
    --------------------------------------------------------
}
procedure TNempPlaylist.Play(aIndex: Integer; aInterval: Integer; Startplay: Boolean; Startpos: Double = 0);
var  NewFile: TPlaylistFile;
     OriginalLength: Int64;
     BackupFileIsPlayedAgain: Boolean;
begin
  // wir haben was getan. Der erste Start ist vorbei.
  fFirstAction := False;
  if not AcceptInput then exit;

  OriginalLength := 0;
  NewFile := Nil;
  BackupFileIsPlayedAgain := False;
  // neues AudioFile aus dem Index bestimmen
  try
      if aIndex = -1 then
      begin
          // Playlist soll selbst entscheiden, was abgespielt werden soll - GetAnAudioFile!
          NewFile := GetAnAudioFile;
          // Note GetAnAudioFile will return the "backupFile" from the medialibrary if it is set!
          if NewFile <> fBackupFile then
              fPlayingIndex := Playlist.IndexOf(NewFile);
          BackupFileIsPlayedAgain := NewFile = fBackupFile;
      end else
          if (aIndex < Playlist.Count) AND (Playlist.Count > 0) then
          begin
              NewFile := TPlaylistFile(Playlist[aIndex]);
              fplayingIndex := aIndex;
          end;
  except
      MessageDlg((BadError_Play), mtError, [mbOK], 0) ;
  end;

   if      AutoDelete                               // User enabled AutoDelete
      And (not fPlayingFileUserInput)               // User did not interact with the player during playback
      And (Player.MainAudioFileIsPresentAndPlaying) // Current file exists and was played
      and ((newFile <> PlayingFile)                 // NewFile is not the current one
           or Player.EndFileProcReached)            //    or lastfile has reached its end
   then
   begin
        if newFile = PlayingFile then   // We will delete the current file
        begin                           // and so the newfile will become
            RemovePlayingFile;          // invalid
            newFile := NIL;
        end
        else
            RemovePlayingFile;          // just delete the current file
   end;

  // Eingaben kurzfristig blocken
  AcceptInput := False;

      if Assigned(NewFile) then
      begin
        SetNewPrebookIndex(NewFile, 0);

        OriginalLength := NewFile.Duration;
        fPlayingFile := NewFile;
        fPlayingFileUserInput := False;
        Player.play(fPlayingFile, aInterval, Startplay, Startpos);  // da wird die Dauer ge�ndert
        // reset the interruptedPlayPosition
        if not BackupFileIsPlayedAgain then
            fInterruptedPlayPosition := 0;

        fPlayingNode := GetNodeWithPlayingFile;
        ScrollToPlayingNode;
        // Anzeige Im Baum aktualisieren
        VST.Invalidate;
        // Knoten aktualisieren
        ActualizeNode(fPlayingNode, false);
        ActualizeCue;
      end;

  // Wenn was schiefgelaufen ist, d.h. der mainstream = 0 ist
  if (Player.MainStream = 0) And (Not Player.URLStream) then
  begin
    try
        if fErrorCount < Playlist.Count then
        begin
          AcceptInput := True;
          if assigned(fPlayingNode) then VST.InvalidateNode(fPlayingNode);
          inc(fErrorCount);

          fDauer := fDauer  - OriginalLength;

          SendMessage(MainWindowHandle, WM_NextFile, 0, 0);
          //PlayNext;
        end else
        begin
          AcceptInput := True;
          if assigned(fPlayingNode) then VST.InvalidateNode(fPlayingNode);
          fDauer := fDauer  - OriginalLength;
          Stop;
          VST.Header.Columns[1].Text := SekToZeitString(fDauer);
          //showmessage(Inttostr(fDauer));
        end;
    except
        MessageDlg((BadError_Play1) + ' (2)', mtError, [mbOK], 0) ;
    end;
  end
  else
  begin
    try
        fErrorCount := 0;
        // ggf Daten des AudioFiles anpassen
        // Unterschied zu oben: Hier werden die Daten der bass.dll genommen!!
        if assigned(fPlayingFile) then
        begin
          fPlayingFile.LastPlayed := fPlayCounter;
          inc(fPlayCounter);
          //OldLength := fPlayingFile.Dauer;
          fPlayingFile.Duration := Round(Player.Dauer);
          fDauer := fDauer + (fPlayingFile.Duration - OriginalLength);
          VST.Header.Columns[1].Text := SekToZeitString(fDauer);
          VST.Invalidate;
        end;
    except
        MessageDlg((BadError_Play1) + ' (3).', mtError, [mbOK], 0) ;
    end;

    // Aufgestaute Nachrichten abarbeiten
    // Grml. Die Multimediakeys machen da wieder �rger.
    // Scheinbar gehts wirklich nur, wenn man AcceptInput erst nach einer gewissen Zeit
    // wieder freigibt...
    tid := timeSetEvent(300, 50, @APM, MainWindowHandle, TIME_ONESHOT);
  end;
end;

procedure TNempPlaylist.PlayBibFile(aFile: TAudioFile; aInterval: Integer);
begin
    if not AcceptInput then exit;

    // increase fPlayingIndex, so we will play the next file in the playlist after this one // no
    if assigned(fPlayingFile) and (fPlayingIndex = Playlist.IndexOf(fPlayingFile)) then
    begin
        // we will backup the index AND the current playposition, so we can
        // start next playback right where we are NOW
        fInterruptedPlayPosition := Player.Time;
        fInterruptedFile := fPlayingFile;

        // additionally, we set the current track on the beginning of the prebook-list
        PrebookList.Insert(0, fPlayingFile);
        if PrebookList.Count > 99 then
        begin
            TAudioFile(PrebookList[PrebookList.Count-1]).PrebookIndex := 0;
            PrebookList.Delete(PrebookList.Count-1);
        end;
        ReIndexPrebookedFiles;
    end;

    if (not assigned(fPlayingFile)) and (fPlayingIndex = -1) then
        fPlayingIndex := 0;

    // Eingaben kurzfristig blocken
    AcceptInput := False;

    if Assigned(aFile) then
    begin
      fBackUpFile.Assign(aFile);
      fPlayingFile := fBackUpFile;

      fPlayingFileUserInput := False;
      // Player.play, not self.play!
      Player.play(fPlayingFile, aInterval, True, 0);  // da wird die Dauer ge�ndert

      fPlayingNode := GetNodeWithPlayingFile;
      // Anzeige Im Baum aktualisieren
      VST.Invalidate;
    end;

  // Wenn was schiefgelaufen ist, d.h. der mainstream = 0 ist
  if (Player.MainStream = 0) And (Not Player.URLStream) then
     // nothing
  else
  begin
      // Aufgestaute Nachrichten abarbeiten
      // Grml. Die Multimediakeys machen da wieder �rger.
      // Scheinbar gehts wirklich nur, wenn man AcceptInput erst nach einer gewissen Zeit
      // wieder freigibt...
      tid := timeSetEvent(300, 50, @APM, MainWindowHandle, TIME_ONESHOT);
  end;

end;

procedure TNempPlaylist.PlayHeadsetFile(aFile: TAudioFile; aInterval: Integer; aPosition: Double);
var i: Integer;
    NewNode: PVirtualNode;
begin
    // Get InssertPosition
    if fPlayingNode <> NIL then
        InsertNode := fPlayingNode.NextSibling
    else
    begin
        InsertNode := VST.GetFirst;
        for i := 0 to fPlayingIndex-1 do
        begin
            if assigned(InsertNode) then
                InsertNode := InsertNode.NextSibling;
        end;
    end;
    // Add File to Playlist
    NewNode := InsertFileToPlayList(aFile);
    Play(NewNode.Index, Player.FadingInterval, True, aPosition);
end;

procedure TNempPlaylist.PlayNext(aUserinput: Boolean = False);
var nextIdx: Integer;
begin
  if not AcceptInput then exit;

  if aUserInput then
      fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtTitleChange;

  if fJumpToNextCueOnNextClick and (Player.JumpToNextCue) then
  begin
      ActualizeCue;  // nothing else todo. Jump complete :D
  end else
  begin
      Player.stop(Player.LastUserWish = USER_WANT_PLAY);
      // GetNextAudioFileIndex can modify fInterruptedPlayPosition
      nextIdx := GetNextAudioFileIndex;
      if fRememberInterruptedPlayPosition then
          Play(nextIdx, Player.FadingInterval, Player.LastUserWish = USER_WANT_PLAY, fInterruptedPlayPosition)
      else
          Play(nextIdx, Player.FadingInterval, Player.LastUserWish = USER_WANT_PLAY, 0)
  end;
end;

procedure TNempPlaylist.PlayNextFile(aUserinput: Boolean = False);
var sPos: Double;
    nextIdx: Integer;
begin
  if not AcceptInput then exit;

  Player.stop; // Neu im Oktober 2008
  if aUserInput then
      fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtTitleChange;

  // GetNextAudioFileIndex can modify fInterruptedPlayPosition
  nextIdx := GetNextAudioFileIndex;

  if fRememberInterruptedPlayPosition then
      sPos := fInterruptedPlayPosition
  else
      sPos := 0;

  if Player.Status = PLAYER_ISPLAYING then
      Play(nextIdx, Player.FadingInterval, True, sPos)
  else
      Play(nextIdx, Player.FadingInterval, False, sPos);
end;

procedure TNempPlaylist.PlayPrevious(aUserinput: Boolean = False);
begin
  if not AcceptInput then exit;
  if aUserInput then
    fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtTitleChange;
  if fJumpToNextCueOnNextClick and (Player.JumpToPrevCue) then
  begin
      ActualizeCue;   // nothing else todo. Jump complete :D
  end else
  begin
      if Player.Time > 5  then
          // just jump to beginning of the current file
          Player.Time := 0
      else
      begin
          if Player.Status = PLAYER_ISPLAYING then
              Play(GetPrevAudioFileIndex, Player.FadingInterval, True)
          else
              Play(GetPrevAudioFileIndex, Player.FadingInterval, False);
      end;
  end;
end;

procedure TNempPlaylist.PlayPreviousFile(aUserinput: Boolean = False);
begin
  if not AcceptInput then exit;
  Player.stop; // Neu im Oktober 2008
  if aUserInput then
      fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtTitleChange;

  if Player.Time > 5  then
      // just jump to beginning of the current file
      Player.Time := 0
  else
  begin
      if Player.Status = PLAYER_ISPLAYING then
          Play(GetPrevAudioFileIndex, Player.FadingInterval, True)
      else
          Play(GetPrevAudioFileIndex, Player.FadingInterval, False);
  end;
end;

procedure TNempPlaylist.PlayFocussed(aSelection: PVirtualNode = Nil);
var Node, NewCueNode: PVirtualNode;
    Data: PTreeData;
    CueTime: Single;
begin
  if not AcceptInput then exit;
  if not assigned(aSelection) then
      Node := VST.FocusedNode
  else
      Node := aSelection;

  if Not Assigned(Node) then Exit;
  if (Not VST.Selected[Node]) and (not assigned(aSelection)) then Exit;

  // add the current title into the history
  UpdateHistory;

  if VST.GetNodeLevel(Node)=0 then
  begin
      Play(Node.Index, Player.FadingInterval, True);
      fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtTitleChange;
  end else
  begin
      fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtSlide;
      Data := VST.GetNodeData(Node);
      if assigned(Data) then
          CueTime := Data^.FAudioFile.Index01
      else CueTime := 0;

      NewCueNode := Node;
      node := VST.NodeParent[Node];
      Data := VST.GetNodeData(Node);

      if assigned(Data) and (Data^.FAudioFile = PlayingFile) then
      begin
          Player.Time := CueTime;
          fActiveCueNode := NewCueNode;
          VST.Invalidate;
          if assigned(fOnCueChanged) then
              fOnCueChanged(Self);
      end else
      begin
          if assigned(Data) then
              Play(Node.Index, Player.FadingInterval, True, CueTime );
      end;
  end;
end;

procedure TNempPlaylist.PlayAgain(ForcePlay: Boolean = False);
begin
  if not AcceptInput then exit;

  if assigned(fPlayingFile) then
  begin
      // play it again (eventually it is a file from the library)
      // we should NOT reset the  fInterruptedPlayPosition here (which would be done in self.play)
      if (Player.Status = PLAYER_ISSTOPPED_MANUALLY) and not Forceplay then
          Player.Play(fPlayingFile, Player.FadingInterval, False)
      else
          Player.Play(fPlayingFile, Player.FadingInterval, True);
  end else
  begin
      if (Player.Status = PLAYER_ISSTOPPED_MANUALLY) and not Forceplay then
          Play(fPlayingIndex, Player.FadingInterval, False)
      else
          Play(fPlayingIndex, Player.FadingInterval, True);
  end;
end;


procedure TNempPlaylist.Pause;
begin
  fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtPause;
  Player.pause;
end;

procedure TNempPlaylist.Stop;
begin
  fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtStop;
  Player.stop;
end;


{
    --------------------------------------------------------
    Deleteing files from the playlist
    --------------------------------------------------------
}
procedure TNempPlaylist.DeleteMarkedFiles;
var i:integer;
  Selectedmp3s: TNodeArray;
  aData: PTreeData;
  NewSelectNode: PVirtualNode;
  allNodesDeleted: Boolean;
begin
  Selectedmp3s := VST.GetSortedSelection(False);
  if length(SelectedMp3s) = 0 then exit;

        VST.BeginUpdate;
        allNodesDeleted := True;

        NewSelectNode := VST.GetNextSibling(Selectedmp3s[length(Selectedmp3s)-1]);
        if not Assigned(NewSelectNode) then
          NewSelectNode := VST.GetPreviousSibling(Selectedmp3s[0]);

        for i := 0 to length(Selectedmp3s)-1 do
        begin
          // Nodes mit Level 1 (CueInfos) werden nicht gel�scht
          if VST.GetNodeLevel(Selectedmp3s[i])=0 then
          begin
              if Selectedmp3s[i] = fPlayingNode then fPlayingNode := Nil;
              if Selectedmp3s[i] = fLastHighlightedSearchResultNode then fLastHighlightedSearchResultNode := Nil;
              aData := VST.GetNodeData(Selectedmp3s[i]);
              if (aData^.FAudioFile) = fPlayingFile then
              begin
                fPlayingIndex := Selectedmp3s[i].Index;
                // Backup playing file
                fBackUpFile.Assign(fPlayingFile);
                // Set the pointer to the backup-file
                fPlayingFile := fBackUpFile;
                Player.MainAudioFile := fBackUpFile;
              end;
              PrebookList.Remove(aData^.FAudioFile);
              RemoveFileFromHistory(aData^.FAudioFile);
              Playlist.Delete(Selectedmp3s[i].Index);
              VST.DeleteNode(Selectedmp3s[i]);
          end else
            allNodesDeleted := False;
        end;

        if assigned(NewSelectNode) AND allNodesDeleted then
        begin
          VST.Selected[NewSelectNode] := True;
          VST.FocusedNode := NewSelectNode;
        end;
        ReIndexPrebookedFiles;

        VST.EndUpdate;
        VST.Invalidate;

        fDauer := ShowPlayListSummary;
        fPlaylistHasChanged := True;
end;


procedure TNempPlaylist.ClearPlaylist(StopPlayer: Boolean = True);
begin
    if StopPlayer then
    begin
        Player.StopAndFree;
        Player.MainAudioFile := Nil;
        fPlayingFile := Nil;
    end else
    begin
        fBackUpFile.Assign(fPlayingFile);
        fPlayingFile := fBackUpFile;
        Player.MainAudioFile := fBackUpFile;
    end;

    HistoryList.Clear;
    PrebookList.Clear;
    Playlist.Clear;
    fLastHighlightedSearchResultNode := Nil;

    fLastHighlightedSearchResultNode := Nil;
    fPlayingNode := Nil;
    fCurrentHistoryFile := Nil;

    fPlayingIndex := 0;
    FillPlaylistView;
    fDauer := ShowPlayListSummary;
    fPlaylistHasChanged := True;
    SendMessage(MainWindowHandle, WM_PlayerStop, 0, 0);
end;


procedure TNempPlaylist.DeleteDeadFiles;
var i: Integer;
begin
  for i := Playlist.Count - 1 downto 0 do
  begin
      if not TPlaylistFile(Playlist.Items[i]).ReCheckExistence then
      begin
          PrebookList.Remove(TPlaylistFile(Playlist.Items[i]));
          HistoryList.Remove(TPlaylistFile(Playlist.Items[i]));
          RemoveFileFromHistory(TPlaylistFile(Playlist.Items[i]));
          Playlist.Delete(i);
      end;
  end;
  ReIndexPrebookedFiles;
  FillPlaylistView;
  fDauer := ShowPlayListSummary;
  fPlaylistHasChanged := True;
end;

procedure TNempPlaylist.removePlayingFile;
var aNode: PVirtualNode;
begin
  aNode := GetNodeWithPlayingFile;
  if assigned(aNode) then
  begin
      if aNode = fLastHighlightedSearchResultNode then fLastHighlightedSearchResultNode := Nil;
      PrebookList.Remove(fPlayingFile);
      RemoveFileFromHistory(fPlayingFile);
      Playlist.Remove(fPlayingfile);
      VST.DeleteNode(aNode);
      ReIndexPrebookedFiles;
  end;
  fDauer := ShowPlayListSummary;
  fPlaylistHasChanged := True;
end;

{
    --------------------------------------------------------
    RepairPlaylist
    Check Non-Existing files, whether the are on the new drive.
    --------------------------------------------------------
}
procedure TNempPlaylist.RepairPlaylist(NewDriveMask: DWord);
begin

end;



{
    --------------------------------------------------------
    RemoveFileFromHistory
    - Delete the entry from the list and set a new fCurrentHistoryFile
    --------------------------------------------------------
}
procedure TNempPlaylist.RemoveFileFromHistory(aFile: TAudioFile);
var aIdx: Integer;
begin
    if aFile = fCurrentHistoryFile then
    begin
        aIdx := HistoryList.IndexOf(fCurrentHistoryFile);
        if aIdx < HistoryList.Count-1 then
        begin
            if aIdx >= 0 then
                fCurrentHistoryFile := TAudioFile(HistoryList[aIdx])
            else
                fCurrentHistoryFile := Nil;
        end
        else
            if aIdx - 1 >= 0 then
                fCurrentHistoryFile := TAudioFile(HistoryList[aIdx - 1])
            else
                fCurrentHistoryFile := Nil;
    end;
    HistoryList.Remove(aFile);
end;


procedure TNempPlaylist.ClearSearch(complete: Boolean = False);
var currentNode: PVirtualNode;
begin
    if not assigned(fVST) then exit;
    currentNode := VST.GetFirst;
    while assigned(currentNode) do
    begin
        fVst.Selected[currentNode] := False;
        currentNode := fVST.GetNext(currentNode);
    end;
    if complete then    
        fLastHighlightedSearchResultNode := Nil;

    fVst.Invalidate;
end;

// just select all hits. No ScrollIntoFocus needed here
procedure TNempPlaylist.SearchAll(aString: String);
var Keywords: TStringList;
    currentFile: TAudioFile;
    currentNode: PVirtualNode;
    Data:PTreeData;
begin
    if not assigned(fVST) then exit;

    Keywords := ExplodeWithQuoteMarks(' ', aString);
    currentNode := VST.GetFirst;
    while assigned(currentNode) do
    begin
          Data := VST.GetNodeData(currentNode);
          currentFile := Data^.FAudioFile;
          if AudioFileMatchesKeywordsPlaylist(currentFile, Keywords) then
          begin
              VST.Selected[currentNode] := true;
              if (currentNode.Parent <> NIL) then
                  VST.Expanded[currentNode.Parent] := true;
          end 
          else
              VST.Selected[currentNode] := False;
          currentNode := VST.GetNext(currentNode);                    
    end;
    fVst.Invalidate;
    Keywords.Free;
end;

procedure TNempPlaylist.Search(aString: String; SearchNext: Boolean = False);
var Keywords: TStringList;
    currentFile: TAudioFile;
    currentNode, TargetNode, startNode: PVirtualNode;
    Data:PTreeData;
begin
    if not assigned(fVST) then exit;

    if assigned(fVst.FocusedNode) then
        currentNode := VST.FocusedNode
    else
        currentNode := fVst.GetFirst;

    if not assigned(currentNode) then exit;

    // deselect this Node later (if needed)
    // oldSelectedNode := currentNode;  
    if SearchNext then
    begin
        if currentNode = fVst.GetLast then
            currentNode := fVst.GetFirst
        else
            currentNode := fVst.GetNext(currentNode);
    end else
    begin
        // we are searching a new keyword (probably)
        // deselect all files
        ClearSearch(False);
    end;

    Keywords := ExplodeWithQuoteMarks(' ', aString);
    TargetNode := Nil;
    startNode := currentNode;
    repeat
        Data := fVST.GetNodeData(currentNode);
        currentFile := Data^.FAudioFile;
        
        if AudioFileMatchesKeywordsPlaylist(currentFile, Keywords) then           
            // found the next hit!
            TargetNode := currentNode;
            
        // if not: try next node
        currentNode := fVST.GetNext(currentNode);
        // or start again at the beginning
        if not assigned(currentNode) then
            currentNode := fVST.GetFirst;               
    until (assigned(TargetNode) or (currentNode = startNode));
    Keywords.Free;

    fLastHighlightedSearchResultNode := TargetNode;
    if assigned(fLastHighlightedSearchResultNode) then
    begin
        fVST.ScrollIntoView(fLastHighlightedSearchResultNode, True);
        fVST.FocusedNode := fLastHighlightedSearchResultNode;
    end;
   
    fVst.Invalidate;
end;



{
    --------------------------------------------------------
    Some GUI-stuff
    --------------------------------------------------------
}
// Setter for property InsertNode

procedure TNempPlaylist.SetInsertNode(Value: PVirtualNode);
begin
  if Assigned(Value) then
  begin
    if VST.GetNodeLevel(Value) = 1 then
      fInsertNode := Value.Parent
    else
      fInsertNode := Value;
  end
  else fInsertNode := NIL;

  if assigned(fInsertNode) then
    fInsertIndex := fInsertNode.Index
  else
    fInsertindex := Playlist.Count;
end;


//Set fInsertNode/fInsertIndex from current position in the list
procedure TNempPlaylist.GetInsertNodeFromPlayPosition;
var i, PrebookIdx: Integer;
    lastPrebookFile: TAudioFile;
begin
    if PrebookList.Count > 0 then
    begin
        lastPrebookFile := TAudioFile(PrebookList[PrebookList.Count - 1]);
        PrebookIdx := Playlist.IndexOf(lastPrebookFile);
        InsertNode := VST.GetFirst;
        for i := 0 to PrebookIdx-1 do
        begin
            if assigned(InsertNode) then
                InsertNode := {f}InsertNode.NextSibling;
        end;
    end else
    begin
        // InsertIndex wird vom InsertNode-Setter (eine Proc weiter oben) entsprechend gesetzt
        // d.h. PlayingNode ist noch in der Liste;
        if fPlayingNode <> NIL then
        begin
          InsertNode := fPlayingNode;
        end else
        begin
          // Playingfile gel�scht - Dateien an der Position einf�gen, die
          // GetNextAudioFile ermitteln wird.
          // note 2019: with the change to insert AFTER the current title,
          //            this is not 100% exact - there will be nother title played
          //            before the new ones. This could be done by "-2", but then it would
          //            be inconsistent, if fPlayingIndex = 0.
          InsertNode := VST.GetFirst;
          for i := 0 to fPlayingIndex-1 do
          begin
            if assigned(InsertNode) then
              InsertNode := {f}InsertNode.NextSibling;
          end;
        end;
    end;
end;

procedure TNempPlaylist.FillPlaylistView;
var i,c: integer;
  aNode,CueNode: PVirtualNode;
  aData: PTreeData;
begin
  if not assigned(fVST) then exit;

  fLastHighlightedSearchResultNode := Nil;
  fVST.BeginUpdate;
  fVST.Clear;
  for i:=0 to Playlist.Count-1 do
  begin
    aNode := VST.AddChild(Nil, TPlaylistFile(Playlist.Items[i]));
    // ggf. Cuelist einf�gen
    if Assigned(TPlaylistFile(Playlist.Items[i]).CueList) AND (TPlaylistFile(Playlist.Items[i]).CueList.Count > 0) then
            for c := 0 to TPlaylistFile(Playlist.Items[i]).CueList.Count - 1 do
            begin
              CueNode := fVST.AddChild(aNode);
              fVST.ValidateNode(CueNode,false);
              aData := fVST.GetNodeData(CueNode);
              aData^.FAudioFile := TPlaylistFile(TPlaylistFile(Playlist.Items[i]).Cuelist[c]);
            end;
  end;
  fVST.EndUpdate;
end;

procedure TNempPlaylist.ActualizeCue;
var NewCueIndex: Integer;
begin
    NewCueIndex := Player.GetActiveCue;
    fActiveCueNode := GetActiveCueNode(NewCueIndex);
    VST.Invalidate;
    if assigned(fOnCueChanged) then
        fOnCueChanged(Self);
end;

procedure TNempPlaylist.ActualizeNode(aNode: pVirtualNode; ReloadDataFromFile: Boolean);
var Data: PTreeData;
    AudioFile: TPlaylistFile;
    OldLength: Int64;

begin
    if not assigned(aNode) then exit;
    Data := VST.GetNodeData(aNode);
    AudioFile := Data^.FAudioFile;
    OldLength := AudioFile.Duration;

    AudioFile.ReCheckExistence;

    case AudioFile.AudioType of
        at_File   : begin
            if not AudioFile.FileIsPresent then
                AudioFile.Duration := 0;

            if ReloadDataFromFile then
                SynchAFileWithDisc(AudioFile, True);
                //SynchronizeAudioFile(AudioFile, AudioFile.Pfad, False);

            if not assigned(AudioFile.CueList) then
            begin
              // nach einer Liste suchen und erstellen
              // yes, always, also on short tracks
              AudioFile.GetCueList;
              AddCueListNodes(AudioFile, aNode);
            end;
        end;

        at_Stream : begin
            AudioFile.Duration := 0;
        end;

        at_CDDA   : begin
            // todo
            if ReloadDataFromFile then
            begin
                if Nemp_MainForm.NempOptions.UseCDDB then
                    AudioFile.GetAudioData(AudioFile.Pfad, GAD_CDDB)
                else
                    AudioFile.GetAudioData(AudioFile.Pfad, 0);
            end;

            // wenn synchfile, dann infos neu lesen. sonst nicht
            // dabei Fallunterscheidung. Bei Nempotions.readCDDB mit cddb, sonst ohne
            //       (geht �ber Flags bei GetAudioData)
        end;
    end;
    fDauer := fDauer + (AudioFile.Duration - OldLength);
    VST.Header.Columns[1].Text := SekToZeitString(fDauer);
    VST.Invalidate;
end;

procedure TNempPlaylist.UpdatePlayListHeader(aVST: TVirtualStringTree; Anzahl: Integer; Dauer: Int64);
begin
  aVST.Header.Columns[0].Text := Format('%s (%d)', [(TreeHeader_Playlist), Playlist.Count]);// 'Titel (' + IntToStr(Playlist.Count) + ')';
  aVST.Header.Columns[1].Text := SekToZeitString(fdauer);
end;

function TNempPlaylist.ShowPlayListSummary: Int64;
var i: integer;
begin
  result := 0;
  for i:= 0 to PlayList.Count - 1 do
    result := result + (PlayList[i] as TAudioFile).Duration;
    //(TreeHeader_Titles)
  VST.Header.Columns[0].Text := Format('%s (%d)', [(TreeHeader_Playlist), Playlist.Count]);//'Titel (' + inttostr(PlayList.Count) + ')';
  VST.Header.Columns[1].Text := SekToZeitString(result);
end;



{
    --------------------------------------------------------
    Sorting/Mixing the playlist
    --------------------------------------------------------
}
// Diese Prozedur findet nach einem Neuaufbau der Playlist
// den PlayingNode wieder und setzt PlayingIndex um
procedure TNempPlaylist.ReInitPlaylist;
begin
  fPlayingNode := GetNodeWithPlayingFile;
  if assigned(fPlayingNode) then
    fPlayingIndex := fPlayingNode.Index
  else
    fPlayingIndex := -1;
  ActualizeCue;
  VST.Invalidate;
end;

procedure TNempPlaylist.Sort(Compare: TListSortCompare);
begin
  Playlist.Sort(Compare);
  FillPlayListView;
  ReInitPlaylist;
  fPlaylistHasChanged := True;
end;

Procedure TNempPlaylist.ReverseSortOrder;
var i : integer;
begin
  for i := 0 to (Playlist.Count-1) DIV 2 do
    Playlist.Exchange(i,Playlist.Count-1-i);
  FillPlayListView;
  ReInitPlaylist;
  fPlaylistHasChanged := True;
end;

Procedure TNempPlaylist.Mix;
var i : integer;
begin
  for i := 0 to Playlist.Count-1 do
    Playlist.Exchange(i,i + random(PlayList.Count-i));
  FillPlayListView;
  ReInitPlaylist;
  fPlaylistHasChanged := True;
end;


{
    --------------------------------------------------------
    Adding Files to the playlist
    --------------------------------------------------------
}
function TNempPlaylist.AddFileToPlaylist(Audiofile: TAudioFile; aCueName: UnicodeString = ''):PVirtualNode;
var NewNode: PVirtualNode;
    //newAudiofile: TAudioFile;
begin
  //newAudiofile := TAudioFile.Create;
  //newAudiofile.Assign(AudioFile);

  Playlist.Add(Audiofile);
  NewNode := VST.AddChild(Nil, Audiofile); // Am Ende einf�gen
  if (Audiofile.Duration > MIN_CUESHEET_DURATION) and (not assigned(Audiofile.CueList)) then
  begin
    // nach einer Liste suchen und erstellen
    Audiofile.GetCueList(aCueName, Audiofile.Pfad);
    AddCueListNodes(Audiofile, NewNode);
  end;

  VST.Invalidate;
  Result := NewNode;
  fDauer := fDauer + Audiofile.Duration;
  UpdatePlayListHeader(VST, Playlist.Count, fDauer);
  fPlaylistHasChanged := True;
end;

function TNempPlaylist.AddFileToPlaylistWebServer(aAudiofile: TAudioFile; aCueName: UnicodeString = ''): TAudioFile;
var NewNode: PVirtualNode;
    newAudiofile: TAudioFile;
begin
    newAudiofile := TAudioFile.Create;
    newAudiofile.Assign(aAudioFile);

    Playlist.Add(newAudiofile);
    NewNode := VST.AddChild(Nil, newAudiofile); // Am Ende einf�gen
    if (newAudiofile.Duration > MIN_CUESHEET_DURATION) and (not assigned(newAudiofile.CueList)) then
    begin
        // nach einer Liste suchen und erstellen
        newAudiofile.GetCueList(aCueName, newAudiofile.Pfad);
        AddCueListNodes(newAudiofile, NewNode);
    end;

    VST.Invalidate;
    Result := newAudiofile;
    fDauer := fDauer + newAudiofile.Duration;
    UpdatePlayListHeader(VST, Playlist.Count, fDauer);
    fPlaylistHasChanged := True;
end;

function TNempPlaylist.AddFileToPlaylist(aAudiofileName: UnicodeString; aCueName: UnicodeString = ''):PVirtualNode;
var NewFile: TPlaylistfile;
begin
    NewFile := TPlaylistfile.Create;
    NewFile.Pfad := aAudiofileName;

    case NewFile.AudioType of
        at_File: //SynchronizeAudioFile(NewFile, aAudioFileName);
                  SynchNewFileWithBib(newFile);
        at_CDDA: begin
            NewFile.GetAudioData(aAudioFileName, 0);
        end;

    end;

    result := AddFileToPlaylist(NewFile, aCueName);
  // NewFile.Free;
end;

function TNempPlaylist.InsertFileToPlayList(Audiofile: TAudioFile; aCueName: UnicodeString = ''):PVirtualNode;
var NewNode: PVirtualNode;
    // newAudiofile: TAudioFile;
begin
  //newAudiofile := TAudioFile.Create;  // no, just insert the file in the parameter.
  //newAudiofile.Assign(AudioFile);

  if InsertNode <> NIL then
  begin
      fInsertIndex := InsertNode.Index;
      Inc(fInsertIndex);

      Playlist.Insert(fInsertIndex, Audiofile);

      //NewNode := VST.InsertNode(fInsertNode, amInsertBefore, Audiofile);
      NewNode := VST.InsertNode(fInsertNode, amInsertAfter, Audiofile);

      if AudioFile.Duration > MIN_CUESHEET_DURATION then
      begin
          Audiofile.GetCueList(aCueName, Audiofile.Pfad);
          AddCueListNodes(Audiofile, NewNode);
      end;
  end else
  begin
      Playlist.Add(Audiofile);
      // indexnode ist NIL, also am Ende einf�gen
      NewNode := VST.AddChild(Nil, Audiofile);
      if AudioFile.Duration > MIN_CUESHEET_DURATION then
      begin
          Audiofile.GetCueList(aCueName, Audiofile.Pfad);
          AddCueListNodes(Audiofile, NewNode);
      end;
  end;
  Result := NewNode;
  InsertNode := NewNode;
  fDauer := fDauer + Audiofile.Duration;
  UpdatePlayListHeader(VST, Playlist.Count, fDauer);
  fPlaylistHasChanged := True;
  VST.Invalidate;
end;

function TNempPlaylist.InsertFileToPlayList(aAudiofileName: UnicodeString; aCueName: UnicodeString = ''):PVirtualNode;
var NewFile: TPlaylistfile;
begin
  NewFile := TPlaylistfile.Create;
  NewFile.Pfad := aAudiofileName;

  case NewFile.AudioType of
      at_File: // SynchronizeAudioFile(NewFile, aAudioFileName);
                SynchNewFileWithBib(NewFile);
      at_CDDA: NewFile.GetAudioData(aAudioFileName, 0);
  end;

  result := InsertFileToPlayList(NewFile, aCueName);
  // NewFile.Free; // no, do not free any longer (2019)
end;


function TNempPlaylist.fGetPreBookCount: Integer;
begin
    result := PrebookList.Count;
end;

procedure TNempPlaylist.AddNodeToPrebookList(aNode: PVirtualnode);
var Data: PTreeData;
    af: TAudioFile;
begin
    if assigned(aNode) and (VST.GetNodeLevel(aNode)=0) then
    begin
        Data := VST.GetNodeData(aNode);
        af := Data^.FAudioFile;
        if PrebookList.IndexOf(af) > -1 then
        begin
            PrebookList.Move(PrebookList.IndexOf(af), 0);
            ReIndexPrebookedFiles;
            VST.Invalidate;
        end else
        begin
            if PrebookList.Count < 99 then
            begin
                PrebookList.Add(af);
                af.PrebookIndex := PreBookList.Count;
                VST.InvalidateNode(aNode);
            end;
        end;

    end;
end;

procedure TNempPlaylist.ReIndexPrebookedFiles;
var i:Integer;
begin
    for i := 0 to PrebookList.Count - 1 do
        TAudioFile(PrebookList[i]).PrebookIndex := i+1;
end;

procedure TNempPlaylist.ProcessKeypress(aDigit: Byte; aNode: PVirtualNode);
var Data: PTreeData;
    oldIndex, newIndex: Integer;
    af: TAudioFile;
    tc: Int64;
begin

    if assigned(aNode) and (VST.GetNodeLevel(aNode)=0) then
    begin
        Data := VST.GetNodeData(aNode);
        af := Data^.FAudioFile;
        tc := GetTickCount;
        if (af = fLastEditedAudioFile) and (tc - fLastKeypressTick < 1000) then
        begin
            oldIndex := fLastEditedAudioFile.PrebookIndex;
            newIndex := (oldIndex mod 10) * 10 + aDigit;
            // But: if NewIndex is bigger than max: Just use the Digit
            //      e.g. max Idx is 15, and we want to change 15 to 1.
            //      newIndex would be set to 51, which will be corrected to 15 in SetNewPrebookIndex
            if (oldIndex=PrebookList.Count) and (newIndex > PrebookList.Count) then
                newIndex := aDigit;
        end else
        begin
            fLastEditedAudioFile := af;
            newIndex := aDigit;
        end;
        fLastKeypressTick := tc;

        SetNewPrebookIndex(af, newIndex);
        VST.Invalidate;
    end;
end;

procedure TNempPlaylist.SetNewPrebookIndex(aFile: TAudioFile;
  NewIndex: Integer);
begin
    // Set the Prebook-Index of the AudioFile to NewIndex
    if aFile.PrebookIndex > 0 then
    begin
        // the file is already in the PrebookList
        if NewIndex <= 0 then
        begin
            // delete the File from the Prebooklist
            aFile.PrebookIndex := 0;
            PrebookList.Remove(aFile);
        end else
        begin
            // Move it in the list to the new position
            if NewIndex-1 > PrebookList.Count-1 then
                PrebookList.Move(aFile.PrebookIndex-1, PrebookList.Count-1)
            else
                PrebookList.Move(aFile.PrebookIndex-1, NewIndex-1);
        end;
    end
    else
    begin
        // the file is NOT already in the prebooklist
        if (NewIndex > 0) and (PrebookList.Count < 99) then
        begin
            // if the index is > 0: insert. Otherwise: Do nothing
            if NewIndex-1 > PrebookList.Count then
                PrebookList.Insert(PrebookList.Count, aFile)
            else
                PrebookList.Insert(NewIndex-1, aFile);
        end;
    end;
    ReIndexPrebookedFiles;
end;

procedure TNempPlaylist.ProcessBufferStringlist;
var i, oldCount: Integer;
begin
  ProcessingBufferlist := True;
  if LastCommandWasPlay then ClearPlaylist;

  oldCount := Playlist.Count;

  for i := 0 to BufferStringList.Count - 1 do
  begin
    AddFileToPlaylist(Bufferstringlist.Strings[i]);
  end;
  BufferStringList.Clear;
  ProcessingBufferlist := False;

  if fFirstAction then   // fFirstAction wird bei Play auf False gesetzt
  begin
      NempPlaylist.Play(PlayingIndex, NempPlayer.FadingInterval, AutoPlayOnStart);
  end else
  begin
      if LastCommandWasPlay and (Playlist.Count  > 0) then
          NempPlaylist.Play(0, NempPlayer.FadingInterval, true)
      else
      begin
          if AutoPlayEnqueuedTitle and (Playlist.Count > oldCount) then
              NempPlaylist.Play(oldCount, NempPlayer.FadingInterval, true)
      end;
  end;
end;


{
    --------------------------------------------------------
    Loading/Saving the playlist
    --------------------------------------------------------
}
procedure TNempPlaylist.LoadFromFile(aFilename: UnicodeString);
begin
  LoadPlaylistFromFile(aFilename, Playlist, AutoScan);
  FillPlaylistView;
  fDauer := ShowPlayListSummary;
  UpdatePlayListHeader(VST, Playlist.Count, fDauer);
  fPlaylistHasChanged := True;
end;

function TNempPlaylist.SuggestSaveLocation(out Directory: String; out Filename: String): Boolean;
var iMax, i: integer;
    aDir, aAlbum, aArtist: String;
    af: TAudioFile;
    OKDir, OKArtist, OKAlbum: Boolean;
begin
    if count = 0 then
    begin
        Directory := '';
        Filename := '';
        result := False
    end
    else
    begin
        if self.Count < 10 then
            iMax := Count
        else
            iMax := 10;

        OKDir    := True;
        OKArtist := True;
        OKAlbum  := True;
        af := TAudioFile(Playlist[0]);
        aDir    := af.Ordner;
        aAlbum  := af.Album;
        aArtist := af.Artist;

        for i := 1 to iMax-1 do
        begin
            af := TAudioFile(Playlist[i]);
            if af.Ordner <> aDir then
                OKDir := False;
            if af.Artist <> aArtist then
                OKArtist := False;
            if af.Album <> aAlbum then
                OKAlbum := False;
        end;

        if okDir then
        begin
            Directory := aDir;
            result := True;
        end
        else
            result := False;

        if okAlbum then
        begin
            if OKArtist then
                Filename := aArtist + ' - ' + aAlbum
            else
                Filename := 'VA - ' + aAlbum;
        end else
        begin
            if OKArtist then
                Filename := aArtist + ' - Mix'
            else
                Filename := '';
        end;
    end;

end;
procedure TNempPlaylist.SaveToFile(aFilename: UnicodeString; Silent: Boolean = True);
var
  myAList: tStringlist;
  i, c: integer;
  aAudiofile: TPlaylistfile;
  ini: TMemIniFile;
  tmpStream: TMemoryStream;
  tmp: AnsiString;
begin
  if (AnsiLowerCase(ExtractFileExt(aFilename)) = '.m3u')
     or (AnsiLowerCase(ExtractFileExt(aFilename)) = '.m3u8') then
  begin
      // Mit Delphi 2009 ist das alles gleich, bis auf die Kodierung am Ende
      myAList := TStringList.Create;
      myAList.Add('#EXTM3U');

      for i := 0 to PlayList.Count - 1 do
      begin
          aAudiofile := Playlist[i] as TPlaylistfile;

          case aAudioFile.AudioType of
              at_File: begin
                  myAList.add('#EXTINF:' + IntTostr(aAudiofile.Duration) + ','
                      + aAudioFile.Artist + ' - ' + aAudioFile.Titel);
                  myAList.Add(ExtractRelativePathNew(aFilename, aAudioFile.Pfad ));
              end;
              at_Stream: begin
                  myAList.add('#EXTINF:' + '0,' + aAudioFile.Description);
                  myAList.Add(aAudioFile.Pfad);
              end;
              at_CDDA: begin
                  myAList.add('#EXTINF:' + IntTostr(aAudiofile.Duration) + ','
                      + aAudioFile.Artist + ' - ' + aAudioFile.Titel);
                  myAList.Add(aAudioFile.Pfad);
              end;
          end;
      end;
      try
          if (AnsiLowerCase(ExtractFileExt(aFilename)) = '.m3u') then
              myAList.SaveToFile(aFilename, TEncoding.Default)
          else
              myAList.SaveToFile(aFilename, TEncoding.UTF8);
      except
              on E: Exception do
              if not Silent then
                  MessageDLG(E.Message, mtError, [mbOK], 0);
      end;
      FreeAndNil(myAList);
  end
  else
  // als pls speichern
  if AnsiLowerCase(ExtractFileExt(aFilename)) = '.pls' then
  begin
      ini := TMeminiFile.Create(aFilename);
      try
          ini.Clear;
          for i := 1 to PlayList.Count do
          // erster Index in pls ist 1, nicht 0
          begin
              aAudiofile := Playlist[i-1] as TPlaylistfile;
              case aAudioFile.AudioType of
                  at_File: begin
                      ini.WriteString ('playlist', 'File'  + IntToStr(i), ExtractRelativePathNew(aFilename, aAudioFile.Pfad ));
                      ini.WriteString ('playlist', 'Title' + IntToStr(i), aAudioFile.Artist + ' - ' + aAudioFile.Titel);
                      ini.WriteInteger('playlist', 'Length'+ IntToStr(i), aAudioFile.Duration);
                  end;
                  at_Stream: begin
                      ini.WriteString ('playlist', 'File'  + IntToStr(i), aAudioFile.Pfad );
                      ini.WriteString ('playlist', 'Title' + IntToStr(i), aAudioFile.Description);
                      ini.WriteInteger('playlist', 'Length'+ IntToStr(i), 0);
                  end;
                  at_CDDA:  begin
                      ini.WriteString ('playlist', 'File'  + IntToStr(i), aAudioFile.Pfad );
                      ini.WriteString ('playlist', 'Title' + IntToStr(i), aAudioFile.Artist + ' - ' + aAudioFile.Titel);
                      ini.WriteInteger('playlist', 'Length'+ IntToStr(i), aAudioFile.Duration);
                  end;
              end;
          end;
          ini.WriteInteger('playlist', 'NumberOfEntries', PlayList.Count);
          ini.WriteInteger('playlist', 'Version', 2);
          try
              Ini.UpdateFile;
          except
              on E: Exception do
                  if not Silent then
                      MessageDLG(E.Message, mtError, [mbOK], 0);
          end;
      finally
          ini.Free
      end;
  end
  else
  // Im Nemp-Playlist-Foramt speichern. �hnlich zu dem Medienbib-Format.
  if AnsiLowerCase(ExtractFileExt(aFilename)) = '.npl' then
  begin
      tmpStream := TMemoryStream.Create;
      try
          // VersionsInfo schreiben
          tmp := 'NempPlaylist';
          tmpStream.Write(tmp[1], length(tmp));
          tmp := '5.0';
          tmpStream.Write(tmp[1], length(tmp));
          // FileCount
          c := Playlist.Count;
          tmpStream.Write(c, SizeOf(Integer));
          // actual Files
          for i := 0 to Playlist.Count - 1 do
          begin
              aAudioFile := TAudioFile(Playlist[i]);
              case aAudioFile.AudioType of
                  at_File: begin
                      aAudioFile.SaveToStream(tmpStream, ExtractRelativePathNew(aFilename, aAudioFile.Pfad ) );
                  end;
                  at_Stream: begin
                      aAudioFile.SaveToStream(tmpStream, aAudioFile.Pfad)
                  end;
                  at_CDDA: begin
                      aAudioFile.SaveToStream(tmpStream, aAudioFile.Pfad)
                  end;
              end;
          end;
          try
              tmpStream.SaveToFile(aFilename);
          except
              on E: Exception do
                  if not Silent then
                      MessageDLG(E.Message, mtError, [mbOK], 0);
          end;
      finally
          tmpStream.Free;
      end;
  end;
end;

(*
procedure TNempPlaylist.GetFromWinamp;
var maxW,i : integer;
    Dateiname: String;
begin
  maxW := GetWinampPlayListLength;

  if maxW = -1 then
      MessageDlg('Winamp not found', mtError, [mbOk], 0)
  else
  begin
      // Bestehende Liste l�schen
      ClearPlaylist;
      // Neu f�llen
      for i:=0 to maxW-1 do
      begin
          Dateiname := GetWinampFileName(i);
          // Wenn Datei nicht existiert, diese auch nicht aufnehmen:
          if Not FileExists(Dateiname) then continue;
          AddFileToPlaylist(Dateiname);
      end;
  end;
end;
*)

 {
    --------------------------------------------------------
    Getter/Setter for some properties
    --------------------------------------------------------
}
function TNempPlaylist.GetCount: Integer;
begin
  result := Playlist.Count;
end;
function TNempPlaylist.GetTime: Double;
begin
  result := Player.Time;
end;
procedure TNempPlaylist.SetTime(Value: Double);
begin
  Player.Time := Value;
  fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtSlide;
  // Cue-Zeug neu setzen
  ActualizeCue;
end;


function TNempPlaylist.GetProgress: Double;
begin
  result := Player.Progress;
end;

procedure TNempPlaylist.SetProgress(Value: Double);
begin
  Player.Progress := Value;
  fPlayingFileUserInput := fPlayingFileUserInput OR DisableAutoDeleteAtUserInput; //DisableAutoDeleteAtSlide;
  // Cue-Zeug neu setzen
  ActualizeCue;
end;

{
    --------------------------------------------------------
    Some stuff for the nodes in the TreeView
    --------------------------------------------------------
}
function TNempPlaylist.GetNodeWithPlayingFile: PVirtualNode;
var k: integer;
    aData: PTreeData;
    aNode: PVirtualNode;
begin
  result := Nil;
  aNode := VST.GetFirst;
  //result := aNode;
  if assigned(aNode) then
  begin
      // Suche den Knoten, der das PlayingFile enth�lt
      for k := 0 to Playlist.Count - 1 do
      begin
        if assigned(aNode) then
        begin
          aData := VST.GetNodeData(aNode);
          if aData^.FAudioFile = fPlayingFile then
          begin
            result := aNode;
            break;
          end else
            aNode := VST.GetNextSibling(aNode);
        end;
      end;
  end;
end;

function TNempPlaylist.GetPlayingIndex: Integer;
var aNode: PVirtualNode;
begin
  aNode := GetNodeWithPlayingFile;
  if assigned(aNode) then
    result := aNode.Index
  else
    result := fPlayingIndex;
end;


procedure TNempPlaylist.ScrollToPlayingNode;
var
  nextnode:PVirtualnode;
begin
  if assigned(fplayingNode) then
  begin
      nextnode := VST.GetFirst;
      While (nextnode <> NIL) AND (NOT (nextnode = fplayingNode)) do
        nextnode := VST.GetNextSibling(nextnode);

      if (nextnode <> Nil) and VST.ScrollIntoView(Nextnode,False) then
        VST.ScrollIntoView(Nextnode,True);
  end;
  // else: No scrolling
end;

procedure TNempPlaylist.AddCueListNodes(aAudioFile: TAudioFile; aNode: PVirtualNode);
var  i:integer;
begin

  if assigned(aNode) and assigned(aAudioFile.CueList) and
    (VST.ChildCount[aNode]=0) then
  begin
      for i := 0 to aAudioFile.CueList.Count - 1 do
        VST.AddChild(aNode, TAudiofile(aAudioFile.Cuelist[i]));
  end;
end;

function TNempPlaylist.GetActiveCueNode(aIndex: Integer): PVirtualNode;
var i: Integer;
    aNode: PVirtualNode;
begin
  result := Nil;
  aNode := fPlayingNode;

  if assigned(aNode) then
    result := VST.GetFirstChild(aNode);

  for i := 1 to aIndex do
  begin
    if assigned(result) then
      result := VST.GetNextSibling(result);
  end;
end;

{
    --------------------------------------------------------
    UpdateHistory
    - add current playingfile to the history
      if we are at the beginning of the historylist, we insert the new file
      at the beginning of the list
      otherwise we add it at the end of the historylist
    --------------------------------------------------------
}
procedure TNempPlaylist.UpdateHistory(Backwards: Boolean = False);
begin
    if backwards then
    begin
        if assigned(fPlayingFile)
        and ((fCurrentHistoryFile = nil) or (HistoryList.IndexOf(fCurrentHistoryFile) = 0 ) )
        then
        begin
            HistoryList.Remove(fPlayingFile); // we MUST NOT have duplicates in this list
            HistoryList.Insert(0, fPlayingFile);
            if HistoryList.Count > 25 then
                HistoryList.Delete(HistoryList.Count-1);
            fCurrentHistoryFile := fPlayingFile;
        end;
    end else
    begin
        if assigned(fPlayingFile)
        and ((fCurrentHistoryFile = nil) or (HistoryList.IndexOf(fCurrentHistoryFile) = HistoryList.Count-1 ) )
        then
        begin
            HistoryList.Remove(fPlayingFile); // we MUST NOT have duplicates in this list
            HistoryList.Add(fPlayingFile);
            if HistoryList.Count > 25 then
                HistoryList.Delete(0);
            fCurrentHistoryFile := fPlayingFile;
        end;
    end;
end;

{
    --------------------------------------------------------
    rebuild the weighted index array used for the weighted RNG
    --------------------------------------------------------
}

procedure TNempPlaylist.SetUseWeightedRNG(aValue: Boolean);
begin
    fUseWeightedRNG := aValue;
    if fUseWeightedRNG then
        RebuildWeighedArray;
end;

procedure TNempPlaylist.RebuildWeighedArray;
var i, curIdx, totalWeight, curWeight: Integer;
    af: TAudiofile;
begin
    SetLength(fWeightedRandomIndices, Playlist.Count, 2);
    curIdx := -1;
    totalWeight := 0;
    // fill the array
    for i := 0 to Playlist.Count-1 do
    begin
        af := TAudioFile(Playlist[i]);
        curWeight := RNGWeights[RatingToArrayIndex(af.Rating)];
        if curWeight > 0 then
        begin
            // it should be possible to randomly play this file
            totalWeight := totalWeight + curWeight;
            inc(curIdx);
            fWeightedRandomIndices[curIdx, 0] := i; // the index of the current file in the playlist
            fWeightedRandomIndices[curIdx, 1] := totalWeight;
        end // else: Weight is 0, it should not be randomly played
    end;

    fMaxWeightedValue := totalWeight;  // used for Random()
    fMaxWeightedIndex := curIdx;       // used for binary search

    fPlaylistHasChanged := False;
end;

function BinIndexSearch(aArray: TIndexArray; aValue: Integer; l, r: Integer): Integer;
var m, mValue, c: Integer;
begin
    if r < l then
    begin
        if r > -1 then
            result := r
        else
            // we do not want -1 as a result!
            result := 0;
    end else
    begin
        m := (l + r) DIV 2;
        mValue := aArray[m, 1];
        c := CompareValue(aValue, mValue);
        if l = r then
            // Suche endet. l Zur�ckgeben - Egal ob das an der Stelle stimmt oder nicht
            result := l
        else
        begin
            if  c = 0 then
                result := m
            else if c > 0 then
                result := BinIndexSearch(aArray, aValue, m+1, r)
                else
                    result := BinIndexSearch(aArray, aValue, l, m-1);
        end;
    end;
end;

function TNempPlaylist.GetRandomPlaylistIndex: Integer;
var rawIndex, searchL, searchR, weightedIndex: Integer;
begin
    if not fUseWeightedRNG then
        result := Random(Playlist.Count)
    else
    begin
        if fPlaylistHasChanged then
            RebuildWeighedArray;

        searchL := 0;
        searchR := fMaxWeightedIndex; // length(fWeightedRandomIndices) - 1;

        // get a weighted result
        rawIndex := Random(fMaxWeightedValue);
        // get the playlist-Index from that index
        weightedIndex := BinIndexSearch(fWeightedRandomIndices, rawIndex, searchL, searchR);

        // binary search may not find the exact rawIndex, probably the first bigger or smaller entry
        // we need always the bigger (or equal) one
        if (fWeightedRandomIndices[weightedIndex, 1] < rawIndex)
            and (length(fWeightedRandomIndices) > weightedIndex + 1)
        then
            inc(weightedIndex);

        result := fWeightedRandomIndices[weightedIndex, 0];
        // to be sure: range check
        if (result < 0) or (result >= Playlist.Count ) then
        begin
            // fallback to regular random
            result := Random(Playlist.Count);
            // set flag to force rebuild of the index array the next time.
            fPlaylistHasChanged := False;
        end;
    end;
end;

{
    --------------------------------------------------------
    Getting an Audiofile
    --------------------------------------------------------
}
function TNempPlaylist.GetAnAudioFile: TPlaylistFile;
var Node: PVirtualNode;
  Data: PTreeData;
begin
  if assigned(PlayingFile) then
    result := PlayingFile
  else
  begin
    // liefert den fokussierten oder den ersten Titel zur�ck
    result := NIL;
    Node := VST.FocusedNode;
    if not Assigned(Node) then
      Node := VST.GetFirst;
    if Assigned(Node) then
    begin
      Data := VST.GetNodeData(Node);
      result := Data^.FAudioFile;
    end;
  end;

end;

function TNempPlaylist.GetNextAudioFileIndex: Integer;
var i:integer;
  tmpAudioFile: TPlaylistfile;
  c: Integer;
  historySuccess: Boolean;
begin
    // 1. add current file to the history, if needed
    // i.e. we are at the end (or the beginning) of the HistoryList
    UpdateHistory;
    // 2. if we are currently "browsing" in the Historylist, get the next one
    if assigned(fCurrentHistoryFile) and (HistoryList.IndexOf(fCurrentHistoryFile) < HistoryList.Count-1 ) then
    begin
        // we are "browsing in the history list"
        c := HistoryList.IndexOf(fCurrentHistoryFile);
        // get the next one
        if (fPlayingFile = fCurrentHistoryFile) and (c < HistoryList.Count-1) then
        begin
            fCurrentHistoryFile := TPlaylistfile(HistoryList[c+1]);
            result := Playlist.IndexOf(fCurrentHistoryFile);
            historySuccess := result > -1
        end else
        begin
            if (c >= 0) then
            begin
                // this occurs, when we browse backwards further than the first "real history file"
                // so the UpdateHistory will add the file, currentHistoryFile is valid and at first position
                // then another title was played
                // and now we want this previous played song, So, we do not change position in HistoryList
                fCurrentHistoryFile := TPlaylistfile(HistoryList[c]);
                result := Playlist.IndexOf(fCurrentHistoryFile);
                historySuccess := result > -1
            end else
            begin
                historySuccess := False;
                result := 0; // dummy, so the compiler dont show a warning
            end;
        end;
    end else
    begin
        historySuccess := False;
        result := 0; // dummy, so the compiler dont show a warning
    end;

    if not historySuccess then
    begin
        if PrebookList.Count > 0 then
        begin
            tmpAudioFile := TAudioFile(PrebookList[0]);
            // the new selected file IS NOT equal to the interrupted file
            // => set the interruptedPLayPosition to 0
            if fInterruptedFile <> tmpAudioFile then
                fInterruptedPlayPosition := 0;

            result := Playlist.IndexOf(tmpAudioFile);
            PrebookList.Delete(0);
            tmpAudioFile.PrebookIndex := 0;
            ReIndexPrebookedFiles;
        end
        else
        begin
            fInterruptedPlayPosition := 0;
            if WiedergabeMode <> 2 then  //  kein Zufall , +1 Mod Count, ggf. Liste neu mischen
            begin
                // Index auf aktuellen  + 1
                if (fPlayingFile <> NIL) and (fPlayingFile <> fBackupFile) then
                  result := PlayList.IndexOf(fPlayingFile) + 1
                else
                    result := fPlayingIndex ; // nicht um eins erh�hen !!

                if result > PlayList.Count-1 then
                begin
                  result := 0;
                  if fAutoMix then
                  begin // Playlist neu durchmischen
                    for i := 0 to Playlist.Count-1 do
                      Playlist.Move(i,i + random(PlayList.Count-i));
                    FillPlaylistView;
                  end;
                end
            end else
            // shufflemode
            begin
                if Playlist.Count = 0 then
                    result := -1
                else begin
                    result := GetRandomPlaylistIndex;

                    // 1st round: Do some more random trials
                    c := 0;
                    tmpAudioFile := PlayList[result] as TPlaylistfile;
                    while ((fPlayCounter - tmpAudioFile.LastPlayed) <= Round(RandomRepeat * Playlist.Count/100))
                          AND (tmpAudioFile.LastPlayed <> 0)
                          AND (c <= 5) do
                    begin
                        inc(c);
                        result := GetRandomPlaylistIndex;
                        tmpAudioFile := PlayList[result] as TPlaylistfile;
                    end;

                    //2nd round: just get the next file
                    c := 0;
                    tmpAudioFile := PlayList[result] as TPlaylistfile;
                    while ((fPlayCounter - tmpAudioFile.LastPlayed) <= Round(RandomRepeat * Playlist.Count/100))
                          AND (tmpAudioFile.LastPlayed <> 0)
                          AND (c <= PlayList.Count) do
                    begin
                        inc(c);
                        result := (result + 1) MOD Playlist.Count;
                        tmpAudioFile := PlayList[result] as TPlaylistfile;
                    end;
                end;
            end;
        end;
    end;
end;

function TNempPlaylist.GetPrevAudioFileIndex: Integer;
var c: Integer;
    historySuccess: Boolean;
begin
    UpdateHistory(True);
    if assigned(fCurrentHistoryFile) and (HistoryList.IndexOf(fCurrentHistoryFile) >= 0 ) then
    begin
        // we are "browsing in the history list"
        c := HistoryList.IndexOf(fCurrentHistoryFile);
        // get the previous one
        if (fPlayingFile = fCurrentHistoryFile) and (c > 0) then
        begin
            fCurrentHistoryFile := TPlaylistfile(HistoryList[c-1]);
            result := Playlist.IndexOf(fCurrentHistoryFile);
            historySuccess := result > -1
        end else
        begin
            if (c > 0) then
            begin
                fCurrentHistoryFile := TPlaylistfile(HistoryList[c]);
                result := Playlist.IndexOf(fCurrentHistoryFile);
                historySuccess := result > -1
            end else
            begin
                historySuccess := False;
                result := 0; // dummy, so the compiler dont show a warning
            end;
        end;
    end else
    begin
        historySuccess := False;
        result := 0; // dummy, so the compiler dont show a warning
    end;

    if not historySuccess then
    begin // fallback to "normal previous"
        if (fPlayingFile <> NIL)  and (fPlayingFile <> fBackupFile) then
            result := PlayList.IndexOf(fPlayingFile) - 1
        else
            result := fPlayingIndex-1;
        if (result < 0) then
            result := Playlist.Count - 1;
        if (result < 0) then
            result := 0;
    end;
end;


procedure TNempPlaylist.UserInput;
begin
  fErrorCount := 0;
end;

procedure TNempPlaylist.RepairBassEngine(StartPlay: Boolean);
var OldTime: Single;
begin
  OldTime := Player.Time;
  StartPlay := StartPlay AND (Player.Status = PLAYER_ISPLAYING);
  // Wiedergabe stoppen
  Player.StopAndFree;
  // BassEngine wieder herstellen
  Player.ReInitBassEngine;
  // Altes Lied wieder starten
  if PlayingFile <> NIL then
  begin
    Play(fPlayingIndex, 0, StartPlay, OldTime);
    Player.Time := OldTime;
  end
end;


{
    --------------------------------------------------------
    Getting an Adiofile with the given ID
    Used by the Nemp Webserver
    --------------------------------------------------------
}
function TNempPlaylist.GetPlaylistIndex(aID: Int64): Integer;
var i: Integer;
    af: TAudioFile;
begin
    result := -1;
    for i := 0 to Playlist.Count - 1 do
    begin
        af := TAudioFile(Playlist[i]);
        if af.WebServerID = aID then
        begin
            result := i;
            break;
        end;
    end;
end;

procedure TNempPlaylist.DeleteAFile(aIdx: Integer);
var aNode: PVirtualNode;
    i: Integer;
    aData: PTreeData;
begin
    VST.BeginUpdate;

    aNode := VST.GetFirst;
    for i := 0 to aIdx-1 do
        aNode := VST.GetNextSibling(aNode);

    if aNode = fPlayingNode then
        fPlayingNode := Nil;

    aData := VST.GetNodeData(aNode);

    if (aData^.FAudioFile) = fPlayingFile then
    begin
        fPlayingIndex := aNode.Index;
        // Backup playing file
        fBackUpFile.Assign(fPlayingFile);
        // Set the pointer to the backup-file
        fPlayingFile := fBackUpFile;
        Player.MainAudioFile := fBackUpFile;
    end;
    PrebookList.Remove(aData^.FAudioFile);
    RemoveFileFromHistory(aData^.FAudioFile);
    Playlist.Delete(aNode.Index);
    VST.DeleteNode(aNode);

    ReIndexPrebookedFiles;

    VST.EndUpdate;
    VST.Invalidate;

    fDauer := ShowPlayListSummary;
    fPlaylistHasChanged := True;
end;

function TNempPlaylist.SwapFiles(a, b: Integer): Boolean;
var tmp, i: Integer;
    NodeA, NodeB: PVirtualNode;

begin
    if a > b then
    begin
        tmp := a;
        a := b;
        b := tmp;
    end;

    if (a > -1) and (b > -1) and (a < Playlist.Count) and (b < Playlist.Count) then
    begin
        NodeA := VST.GetFirst;
        for i := 0 to a-1 do
            NodeA := VST.GetNextSibling(NodeA);
        NodeB := NodeA;
        for i := a to b-1 do
            NodeB := VST.GetNextSibling(NodeB);
        // change fPlayingIndex
        if NodeA = fPlayingNode then
            fPlayingIndex := NodeB.Index
        else
            if NodeB = fPlayingNode then
                fPlayingIndex := NodeA.Index;

        Playlist.Move(a,b);
        VST.MoveTo(NodeA, NodeB, amInsertAfter, false);
        result := True;
    end else
        result := False;

    fPlaylistHasChanged := True;
end;

procedure TNempPlaylist.ResortVotedFile(aFile: TAudioFile; aIndex: Cardinal);
var i, newIdx: Integer;
    currentNode, iNode: PVirtualNode;
    iData: PTreeData;
    iFile: TAudioFile;
begin
    // get the node with the voted Audiofile
    currentNode := VST.GetFirst;
    for i := 0 to aIndex-1 do
        currentNode := VST.GetNextSibling(currentNode);

    if currentNode = fPlayingNode then
        exit; // no action required

    // get the node, where it should be moved to
    GetInsertNodeFromPlayPosition;
    iNode := InsertNode;
    if assigned(iNode) then
    begin
        iData := VST.GetNodeData(iNode);
        iFile := iData.FAudioFile;
        while assigned(iNode) and (iNode <> currentNode) and (iFile.VoteCounter >= aFile.VoteCounter) do
        begin
            iNode := VST.GetNextSibling(iNode);
            if assigned(iNode) then
            begin
                iData := VST.GetNodeData(iNode);
                iFile := iData.FAudioFile;
            end;
        end;
        // votes of iFile are < aFile.VoteCounter now
        // (or iNode = Nil)
        if (iNode <> currentNode) then
        begin
            if assigned(iNode) then
            begin
                if aIndex < iNode.Index then
                    newIdx := iNode.Index - 1
                else
                    newIdx := iNode.Index;
                Playlist.Move(aIndex, newIdx);
                VST.MoveTo(currentNode, iNode, amInsertBefore, false);
            end else
            begin
                iNode := VST.GetLast;
                if assigned(iNode) then
                begin
                    Playlist.Move(aIndex, Playlist.Count - 1);
                    VST.MoveTo(currentNode, iNode, amInsertAfter, false);
                end // else: Nothing to do, there is no Node in the Tree
            end;
        end;

    end else
    begin
        // move aFile to the end of the playlist
        iNode := VST.GetLast;
        if assigned(iNode) then
        begin
            Playlist.Move(aIndex, Playlist.Count - 1);
            VST.MoveTo(currentNode, iNode, amInsertAfter, false);
        end
    end;



    // fPlayingIndex korrigieren
    ReInitPlaylist;
    fPlaylistHasChanged := True;
end;

{
    --------------------------------------------------------
    Unify the rating for a given Audiofile (identified by its filename)
    Used when the user changes the rating of a file
    --------------------------------------------------------
}
procedure TNempPlaylist.UnifyRating(aFilename: String; aRating: Byte; aCounter: Integer);
var i: Integer;
    af: TAudioFile;
begin
    for i := 0 to Playlist.Count - 1 do
    begin
        af := TAudioFile(Playlist[i]);
        if af.Pfad = aFilename then
        begin
            af.Rating := aRating;
            af.PlayCounter := aCounter;
        end;
        if af = Player.MainAudioFile then
            Spectrum.DrawRating(af.Rating);
    end;
end;

procedure TNempPlaylist.CollectFilesWithSameFilename(aFilename: String;
  Target: TObjectList);
var i: Integer;
    af: TAudioFile;
begin
    for i := 0 to Playlist.Count - 1 do
    begin
        af := TAudioFile(Playlist[i]);
        if af.Pfad = aFilename then
            Target.Add(af);
    end;
end;


end.
