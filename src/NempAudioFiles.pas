{

    Unit NempAudioFiles

    Defines and implements the class TAudioFile
    One of the Basic-Units

    ---------------------------------------------------------------
    Nemp - Noch ein Mp3-Player
    Copyright (C) 2005-2010, Daniel Gaussmann
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


unit NempAudioFiles;

interface

uses windows, classes, SysUtils, math, Contnrs, ComCtrls, forms,
  AudioFileBasics, Mp3FileUtils, ID3v2Frames, ID3GenreList,
  Mp3Files, FlacFiles, OggVorbisFiles, M4AFiles, M4aAtoms,
  VorbisComments, cddaUtils, System.Types,
  ComObj, graphics, variants, WmaFiles, WavFiles, AudioFiles,
  Apev2Tags, ApeTagItem, MusePackFiles,
  strUtils, md5, U_CharCode, Nemp_ConstantsAndTypes, Hilfsfunktionen, Inifiles,
  DateUtils, RatingCtrls;

var
    NempCharCodeOptions: TConvertOptions;

type

    TTagType = ( TT_ID3v2, TT_OggVorbis, TT_Flac, TT_Ape, TT_M4A);

    TAudioFileAction = (afa_None,
                        afa_SaveRating,
                        afa_RefreshingFileInformation,
                        afa_AddingFileToLibrary,
                        afa_PasteFromClipboard,
                        afa_DroppedFiles,
                        afa_NewFile,
                        afa_DirectEdit,
                        afa_EditingDetails,
                        afa_LyricSearch,
                        afa_TagSearch,
                        afa_TagCloud,
                        afa_ReplayGain
                        );

    TNempAudioError = (
                AUDIOERR_None,  // everthing's fine
                // General File-Errors
                AUDIO_FILEERR_NoFile,
                AUDIO_FILEERR_FOpenCrt,  // FileOpen failed (used in Stream-Methods)
                AUDIO_FILEERR_FOpenR,    // OpenRead failed (ReadfromFile)
                AUDIO_FILEERR_FOpenRW,   // OpenReadWrite failed (WriteToFile)
                AUDIO_FILEERR_FOpenW,    // unused
                AUDIO_FILEERR_SRead,     // reading from Stream failed
                AUDIO_FILEERR_SWrite,    // writing into Stream failed
                // ID3-Tags
                AUDIO_ID3ERR_Cache,      // Caching AudioData failed
                AUDIO_ID3ERR_NoTag,      // No ID3Tag found (should be ignored)
                AUDIO_ID3ERR_Invalid_Header,  // invalid Id3v2-Subversion
                AUDIO_ID3ERR_Compression,     // Compressed ID3v2-Tag (unparsable for Mp3FileUtils)
                AUDIO_ID3ERR_Unclassified,    // Some other Exception, MessageBox will popup
                // MPEG
                AUDIO_MPEGERR_NoFrame,        // Not a valid mp3File
               // OggVorbis // OVErr_None, OVErr_NoFile, OVErr_FileCreate, OVErr_FileOpenR, OVErr_FileOpenRW as above
                AUDIO_OVErr_InvalidFirstPageHeader,
                AUDIO_OVErr_InvalidFirstPage,
                AUDIO_OVErr_InvalidSecondPageHeader,
                AUDIO_OVErr_InvalidSecondPage,
                AUDIO_OVErr_CommentTooLarge,
                AUDIO_OVErr_BackupFailed,
                AUDIO_OVErr_DeleteBackupFailed,
                // Flac // FlacErr_None, FlacErr_NoFile, FlacErr_FileCreate, FlacErr_FileOpenR, FlacErr_FileOpenRW as above

                AUDIO_FlacErr_InvalidFlacFile,      // Invalid FlacFile
                AUDIO_FlacErr_MetaDataTooLarge,      // MetaData too large to write

                AUDIO_ApeErr_InvalidApeFile,
                AUDIO_ApeErr_InvalidApeTag,

                AUDIO_M4aErr_Invalid_TopLevelAtom,
                AUDIO_M4aErr_Invalid_UDTA,
                AUDIO_M4aErr_Invalid_METAVersion,
                AUDIO_M4aErr_Invalid_MDHD,
                AUDIO_M4aErr_Invalid_STSD,
                AUDIO_M4aErr_Invalid_STCO,
                AUDIO_M4aErr_Invalid_DuplicateUDTA,
                AUDIO_M4aErr_Invalid_DuplicateTRAK,

                AUDIOERR_UnsupportedMediaFile,
                AUDIOERR_EditingDenied,
                AUDIOERR_DriveNotReady,
                AUDIOERR_NoAudioTrack,

                AUDIOERR_ReplayGain_TooManyChannels,
                AUDIOERR_ReplayGain_InitGainAnalysisError,
                AUDIOERR_ReplayGain_AlbumGainFreqChanged,

                AUDIOERR_Unkown   );

 const
    AudioErrorString: Array[TNempAudioError] of String = (
              'No Error',
              'File not found',
              'FileCreate failed.',
              'Could not read from file',
              'Could not write into file',
              'File is read-only',
              'Reading from stream failed',
              'Writing to stream failed',
              // Id3
              'Caching audiodata failed',
              'No ID3-Tag found',
              'Invalid header for ID3v2-Tag',
              'Compressed ID3-Tag found',
              'Unknown ID3-Error',
              // mpeg
              'Invalid MP3-File: No audioframe found',
              // Ogg
              'Invalid Ogg-Vorbis-File: First Vorbis-Header corrupt',
              'Invalid Ogg-Vorbis-File: First Ogg-Page corrupt',
              'Invalid Ogg-Vorbis-File: Second Vorbis-Header corrupt',
              'Invalid Ogg-Vorbis-File: Second Ogg-Page corrupt',
              'Ogg-Vorbis-Comment too large (not supported by Nemp, sorry)',
              'Backup failed',
              'Delete backup failed',
              // Flac
              'Invalid Flac-File',
              'Metadata-Block exceeds maximum size',
              //
              'Invalid Ape File',
              'Invalid Apev2Tag' ,
              //

              'Invalid Top-Level Atom (probably a video file?)',
              'Invalid UDTA Atom',
              'Invalid META Version',
              'Invalid MDHD Atom',
              'Invalid STSD Atom',
              'Invalid STCO Atom',
              'Duplicate UDTA Atoms',
              'Duplicate TRAK Atoms (probably a video file?)',
              //
              'Metadata is not supported in this file type',
              'Quick access to metadata denied',
              // CDDA
              'Drive not ready',
              'No Audio track',

              // ReplayGain
              'Too many channels',                               // AUDIOERR_ReplayGain_TooManyChannels,
              'Error initialising ReplayGain calculation',       //  AUDIOERR_ReplayGain_InitGainAnalysisError,
              'Inconsistent track frequency on this album', //  AUDIOERR_ReplayGain_AlbumGainFreqChanged,

              // unknown
              'Unknown Error'
    );

    M4ARating: AnsiString = 'NEMP RATING';
    M4APlayCounter: AnsiString = 'NEMP PLAYCOUNTER';
    M4AUserCoverID: AnsiString = 'NEMP COVER ID';


 type
    TAudioType = (at_Undef, at_File, at_Stream, at_CDDA, at_CUE);


    // Class TTag: Used for the TagCloud
    TTag = class
      private
          //
          fBreadCrumbIndex: Integer;
          fIsAutoTag: Boolean;

          fTotalCount: Integer; // the total count of this Tag. (= Count in initial cloud)

          function GetCount: Integer;
      protected
          // The key of the tag, e.g. 'Pop', 'really great song', '80s', ...
          fKey: String;

          fTranslate: Boolean;
      public
          // Stores all AudioFiles with this Tag.
          AudioFiles: TObjectList;
          // The number of AudioFiles tagged with this Tag.
          property count: Integer read GetCount;
          property Key: String read fKey;
          property IsAutoTag: Boolean read fIsAutoTag write fIsAutoTag;
          property TotalCount: Integer read fTotalCount write fTotalCount;

          property BreadCrumbIndex: Integer read fBreadCrumbIndex write fBreadCrumbIndex;
          constructor Create(aKey: String; aTranslate: Boolean);
          destructor Destroy; override;
    end;



    TAudioFile = class
    private
        // some properties
        // read it from ID3- or other tags
        fTitle: UnicodeString;
        fComment: UnicodeString;
        fLyrics: UTF8String;
        //fDescription: UnicodeString;
        fTrack: Integer;
        fCD: UnicodeString;
        fRating: Byte;
        fPlayCounter: Cardinal;
        // some more properties
        // read it from the file itself
        fDuration: Integer;
        fChannelModeIDX: Byte;
        fSamplerateIDX: Byte;
        fVBR: Boolean;
        fBitrate: Word;
        fFileSize: Integer;
        fFileAge: TDateTime;
        // CoverID: a md5-hash-like string
        fCoverID: String;

        //fTrackGainStr: String;
        //fAlbumGainStr: String;

        fTrackGain: Single;
        fAlbumGain: Single;
        fTrackPeak: Single;
        fAlbumPeak: Single;

        // fDriveID: New in 4.13, used for loading/saving media library files into a stream.
        //           it is the index of the drive in the DriveList, to assign a proper Drive letter
        fDriveID: Integer;

        fVoteCounter: Integer;

        fFavorite: Byte; // Marker for the new favorite list (preselect files for the playlist)
                         // Byte ist used instead of Bool, because there was still a DummyByte in the fileformat left, but no Bool

        fAudioType: TAudioType; // undef, File, Stream, CD-Audio

        // In the playlist, every AudioFile can have a list
        // of TAudiofiles (CueList), if there is a cuefile present
        // These subfiles starts at position Index01
        // (in cuefiles this is named that way)
        FIndex01: Single; // Speichert den Cue-Index

        // fStrings stores Properties like Artist and Album, which
        // are used for preselection ("browselists")
        // As I do not want to 7x7=49 different sort function,
        // I set the array-index, which is used then in the sort-function
        // Note to self: Eventually Obsolete, if I implement the better
        //               Sort-Stuff in the Medialibrary
        //  Should also work with 2 function-pointers
        //  and one Uber-Sort-function, which calls these 2 in the right order.
        FStrings: array [TAudioFileStringIndex] of UnicodeString;

        // key1, key2: Used for the Browse-Lists
        // These values must be set when building the "AllArtist-Lists" and so on
        fKey1: UnicodeString;
        fKey2: UnicodeString;

        // List of all Tags for this Audiofile
        // This List is managed in class TTagCloud
        fTagList: TObjectList;

        function fGetTagList: TObjectList;

        // ChannelMode/Samplerate is used most times for displaying as a String
        function GetChannelMode: String;
        function GetChannelModeShort: String;
        function GetSamplerate: String;
        function GetSamplerateShort: String;

        // Checks whether lyrics exist or not
        function fGetLyricsExisting: Boolean;

        function fGetExtension: String;

        function GetString(Index: TAudioFileStringIndex): UnicodeString;
        procedure SetString(Index: TAudioFileStringIndex; const Value: UnicodeString);
        function GetFileAgeSortString: String;

        function GetReplaceString(ReplaceValue: Integer): String;

        function GetPath: UnicodeString;
        procedure SetPath(const Value: UnicodeString);

        function fGetPlaylistTitleString: UnicodeString;

        function fGetNonEmptyTitle: UnicodeString;
        function fGetProperFilename: UnicodeString;

        function fGetIsFile: Boolean;
        function fGetIsStream: Boolean;
        function fGetIsCDDA: Boolean;
        function fGetIsLocalFile: Boolean;

        function fGetRoundedRating: Double;

        procedure GetMp3Info(aMp3File: TMp3File; filename: UnicodeString; Flags: Integer = 0);
        procedure GetFlacInfo(aFlacFile: TFlacFile; Flags: Integer = 0);
        procedure GetM4AInfo(aM4AFile: TM4aFile; Flags: Integer = 0);
        procedure GetOggInfo(aOggFile: TOggVorbisFile; Flags: Integer = 0);
        procedure GetWmaInfo(aWmaFile: TWmaFile);
        procedure GetWavInfo(aWavFile: TWavFile);
        procedure GetExoticInfo(aBaseApeFile: TBaseApeFile; aType: TAudioFileType; Flags: Integer = 0);

        function GetCDDAInfo(Filename: UnicodeString; Flags: Integer = 0): TCDDAError;

        // GetCoverFrom*: Used by the VCL-Thread only to display a proper Cover
        // only used, when there is no <CoverID>.jpg in the Cover-Archive
        function GetCoverFromMp3 (aMp3File: TMp3File   ; aCoverBmp: TBitmap): Boolean;
        function GetCoverFromFlac(aFlacFile: TFlacFile ; aCoverBmp: TBitmap): Boolean;
        function GetCoverFromM4A (aM4AFile: TM4aFile   ; aCoverBmp: TBitmap): Boolean;
        function GetCoverFromAPE (aBaseApeFile: TBaseApeFile; aCoverBmp: TBitmap): Boolean;

        // GetCoverStreamFrom*:
        // Used by VCl and secondary Threads while initialising a new <CoverID>.jpg
        // The stream is then processed by an IWICImagingFactory to save the resized <CoverID>.jpg in the coverArchive
        function GetCoverStreamFromMp3 (aMp3File: TMp3File   ; var aPicStream: TMemoryStream): Boolean;
        function GetCoverStreamFromFlac(aFlacFile: TFlacFile ; var aPicStream: TMemoryStream): Boolean;
        function GetCoverStreamFromM4A (aM4AFile: TM4aFile   ; var aPicStream: TMemoryStream): Boolean;
        function GetCoverStreamFromAPE (aBaseApeFile: TBaseApeFile; var aPicStream: TMemoryStream): Boolean;



        // no tags found - set default values
        procedure SetUnknown;

        (*
        procedure SetMp3Data(aMp3File: TMp3File);
        procedure SetOggVorbisData(aOggFile: TOggVorbisFile);
        procedure SetFlacData(aFlacFile: TFlacFile);
        procedure SetM4AData(aM4AFile: TM4AFile);
        procedure SetExoticInfo(aBaseApeFile: TBaseApeFile);
        *)

        // reading text information from a stream. This method is only used for reading files created
        // by Nemp 4.12 or earlier.
        // in the current versions since 4.13, the methods from the unit NempFileUtils are used
        // (not only for audiofiles, but also for other information stored into the *.gmp file
        //function WriteTextToStream(aStream: TStream; ID: Byte; wString: UnicodeString): LongInt;
        function ReadTextFromStream_DEPRECATED(aStream: TStream): UnicodeString;
    public
        // CueList: AudioFiles in the Playlist can have a Cuesheet.
        // Each entry in this sheet is realized as a TAudiofile, which are
        // stored in this list.
        CueList: TObjectlist;

        // some fields used quite often in several ways.
        FileIsPresent: Boolean;

        // Counter for Random playback
        // If a file was played, it will be "blocked" for some time
        // to avoid repeating a file to often.
        // Yes, this is not "really random",
        // but humans believe this is "more random" ;-)
        LastPlayed: Integer;

        // ViewCounter is used by searching in the library.
        // Everytime some audiofiles are displayed in the main VST,
        // the displayed files get a new ViewCounter-ID to identify them
        // fast at "better Searches". See comments in BibSearcherClass.
        // 4.7.3: Disabled this stuff
        // ViewCounter: Integer;

        // WebServerID is used by Nemp WebServer
        // Each file will get ist own ID, which will be used for downloading
        // the file without publishing the filename in the local filesystem.
        WebServerID: Integer;

        // PrebookIndex is used for prebooking some files for the playlist
        // PrebookIndex should be equal to the Index of the file in the
        // Playlist.PrebookList
        PrebookIndex: Integer;

        // RawTags: #13#10-separated Tags
        // Management of these Strings (except loading/saving) is done in Class TTagCloud
        // RawTagAuto: UTF8String;
        RawTagLastFM: UTF8String;
        // RawTagUserDefined: UTF8String; // Never used this
        // Used in TagEditor/CloudTag.RenameTag
        // True indicates that the ID3Tag of the file should be rewritten
        ID3TagNeedsUpdate: Boolean;

        property Titel:  UnicodeString Read fTitle write fTitle;                        // 2
        property Artist: UnicodeString Index siArtist read GetString write SetString;  // 1
        property Album:  UnicodeString Index siAlbum read GetString write SetString;   // 3
        property Ordner: UnicodeString Index siOrdner read GetString;
        property Genre:  UnicodeString Index siGenre read GetString write SetString;
        property Year:   UnicodeString Index siJahr read GetString write SetString;    // 9
        property Comment:UnicodeString read fComment write fComment;
        property Lyrics : UTF8String   read fLyrics write fLyrics;
        property LyricsExisting: Boolean read fGetLyricsExisting;
        property Description: UnicodeString read fComment write fComment;//read fDescription write fDescription;
        property Dateiname: UnicodeString Index siDateiname read GetString;
        property FileAgeString: UnicodeString Index siFileAge read GetString;
        property FileAgeSortString: UnicodeString read GetFileAgeSortString;

        property Extension: String read fGetExtension;
        property Strings[Index: TAudioFileStringIndex]: UnicodeString read GetString write SetString;
        property Index01: single read FIndex01;

        property CoverID: String read fCoverID write fCoverID;
        //property Track: Byte read fTrack write fTrack;
        property Track: Integer read fTrack write fTrack;
        property CD: UnicodeString read fCD write fCD;
        property Duration: Integer read fDuration write fDuration;
        property Rating: Byte read fRating write fRating;
        property RoundedRating: Double read fGetRoundedRating;
        property PlayCounter: Cardinal read fPlayCounter write fPlayCounter;
        property ChannelMode: String read GetChannelMode;
        property ChannelModeShort: String read GetChannelModeShort;
        // note: ChannelModeInt and SampleRateInt gives the INDEX in the Array,
        //       not the real values
        property ChannelModeInt: Byte read fChannelModeIDX;
        property SampleRate: String read GetSamplerate;
        property SampleRateShort: String read GetSamplerateShort;
        property SampleRateInt: Byte read fSampleRateIDX;
        property vbr: boolean read fVBR;
        property Bitrate: word read fBitrate write fBitrate;
        property Size: Integer read fFileSize;
        property FileAge: TDateTime read fFileAge;
        
        property Pfad: UnicodeString read GetPath write SetPath;
        property PlaylistTitle: UnicodeString read fGetPlaylistTitleString;
        property FilenameForUSBCopy: UnicodeString read fGetProperFilename;

        property Key1: UnicodeString read fKey1 write fKey1;
        property Key2: UnicodeString read fKey2 write fKey2;

        property Taglist: TObjectList read fgetTagList;
        // property TagDisplayString: String read fGetTagDisplayString;
        property NonEmptyTitle: UnicodeString read fGetNonEmptyTitle;

        property AudioType: TAudioType read fAudioType write fAudioType;

        // isFile: True if the AudioFile is actually a File
        property IsFile: Boolean read fGetIsFile;
        property isStream: Boolean read fGetIsStream;
        property isCDDA: Boolean read fGetIsCDDA;
        property isLocalFile: Boolean read fGetIsLocalFile;

        property VoteCounter: Integer read fVoteCounter write fVoteCounter;
        property Favorite: Byte read fFavorite write fFavorite;

        property DriveID: Integer read fDriveID write fDriveID;

        //property TrackGainStr: String read fTrackGainStr write fTrackGainStr;
        //property AlbumGainStr: String read fAlbumGainStr write fAlbumGainStr;

        property TrackGain: Single read fTrackGain write fTrackGain;
        property AlbumGain: Single read fAlbumGain write fAlbumGain;

        property TrackPeak: Single read fTrackPeak write fTrackPeak;
        property AlbumPeak: Single read fAlbumPeak write fAlbumPeak;

        constructor Create;
        destructor Destroy; override;

        // Copy the data from aAudiofile
        procedure Assign(aAudioFile: TAudioFile);
        // AssignLight: Copy Data, except Lyrics and RawTagsLastFM
        //   used for the webserver-copy of the MedienBib.
        //   Lyrics are not used in webserver but needs much place
        procedure AssignLight(aAudioFile: TAudioFile);

        // Change the Driveletter from a file
        procedure SetNewDriveChar(aChar: Char);

        // Check, whether the file exist, cdda is present, ..
        // and set FileIsPresent again
        function ReCheckExistence: Boolean;

        function GetAudioData(filename: UnicodeString; Flags: Integer = 0): TNempAudioError;
        function GetCueList(aCueFilename: UnicodeString =''; aAudioFilename: UnicodeString = ''): boolean; // R�ckgabewert: Liste erstellt/nicht erstellt

        // Write the Meta-Data back to the file
        // This method will call a proper sub-methode like SetMp3Info
        // function SetAudioData(allowChange: Boolean): TNempAudioError;

        function PreparingWriteChecks(allowChange: Boolean): TNempAudioError;
        procedure EnsureID3v2Exists(aMp3File: TMp3File);
        function WriteStringToMetaData(aValue: String; ColumnIndex: Integer; allowChange: Boolean): TNempAudioError;
        function WriteLyricsToMetaData(aValue: UTF8String; allowChange: Boolean): TNempAudioError;
        function WriteRawTagsToMetaData(aValue: UTF8String; allowChange: Boolean): TNempAudioError;
        function WriteRatingsToMetaData(aRating: Integer; allowChange: Boolean): TNempAudioError;
        function WritePlayCounterToMetaData(aPlayCounter: Integer; allowChange: Boolean): TNempAudioError;

        function WriteReplayGainToMetaData(aTrackGain, aAlbumGain, aTrackPeak, aAlbumPeak: Single; Flags: Integer; allowChange: Boolean): TNempAudioError;
        function WriteUserCoverIDToMetaData(aValue: AnsiString; allowChange: Boolean): TNempAudioError;
        function GetUserCoverIDFromMetaData(TagFile: TGeneralAudioFile): String;

        // new in 4.12: Get Front-Cover for the Player from the Metadata.
        function GetCoverFromMetaData(aCoverBmp: TBitmap): boolean;
        function GetCoverStreamFromMetaData(aCoverStream: TMemoryStream; TagFile: TGeneralAudioFile): boolean;

        // save the data here in a ";"-separated string for csv-export
        function GenerateCSVString: UnicodeString;

        // Load the data from a .gmp-file (medialib-format)
        function LoadSizeInfoFromStream_DEPRECATED(aStream: TStream): Integer;

        procedure LoadDataFromStream(aStream: TStream; JustForPlaylist: Boolean);
        procedure LoadDataFromStream_DEPRECATED(aStream: TStream);
        procedure LoadFromStream_DEPRECATED(aStream: TStream);
        // load the data from a .npl-file (Nemp-playlist-format)
        // the difference is about URLs as paths and relative filenames in playlists
        procedure LoadFromStreamForPlaylist_DEPRECATED(aStream: TStream);
        // save the data to the stream. gmp/npl-stuff is done via the second parameter
        function SaveToStream(aStream: TStream; aPath: UnicodeString = ''): LongInt;

        // Set the samplerate. Called by the playerclass.
        // Samplerate came from the bass.dll, but not directly compatible to
        // the Index-system here.
        procedure SetSampleRate(aRate: Integer);

        // QuickFileUpdate:
        // Set only the Rating and the Playcounter and write it to the file
        //function QuickUpdateTag(allowChange: Boolean): TNempAudioError;

        // Used in VST, DetailForm, MainForm.Details to replace empty Values by the chosen one
        // (Empty string)
        // 'N/A'
        // Filename
        // Directory (last part)
        // Directory
        // Complete path

        function GetArtistForVST(ReplaceValue: Integer): String;
        function GetTitleForVST(ReplaceValue: Integer): String;
        function GetAlbumForVST(ReplaceValue: Integer): String;
        function GetBitrateForVST: String;
        function GetDurationForVST: String;

        // returns a Hint for playlist- and medialibrary- VST
        function GetHint(naArtist, naTitle, naAlbum: Integer): UnicodeString;


        function GetReplacedArtist(ReplaceValue: Integer): String;
        function GetReplacedTitle (ReplaceValue: Integer): String;
        function GetReplacedAlbum (ReplaceValue: Integer): String;

        // function GetTagDisplayString(allowEdit: Boolean): String;

        // for the Double-Click Action in the VTS-Details.
        // check for values that "make sense"
        function IsValidArtist: Boolean;
        function IsValidTitle : Boolean;
        function IsValidAlbum : Boolean;
        function IsValidYear  : Boolean;
        function IsValidGenre : Boolean;

        function HasSupportedTagFormat: Boolean;
        // editing tags
        // result: True iff the tag was contained in the file
        function ChangeTag(oldTag, newTag: String): Boolean;
        function ContainsTag(aTag: String): Boolean;
        function RemoveTag(aTag: String): Boolean;

        //function RemoveTag(aTag: String): Boolean;
        //function RenameTag(oldTag, newTag: String): Boolean;

        // creates a copy of the Audiofile and adds the copy to the list
        procedure AddCopyToList(aList: TObjectList);


    end;

    // Okay. This doesnt make any sense. I wanted to create subclasses of
    // TAudiofile here, as some properties are only used by the playlist.
    // But all i coded was this re-definition...
    TPlaylistFile = TAudioFile;

    // Types used in the VirtualStringTrees
    TTreeData = record
      FAudioFile : TAudioFile;
    end;
    PTreeData = ^TTreeData;

    // Note to self: This is maybe obsolete, when the bottom part of the
    // mainwindow is changed
    PCoverTreeData = ^TCoverTreeData;
    TCoverTreeData = record
        Image: TBitmap;
    end;

    TErrorLog = class
        public
            Action: TAudioFileAction;
            AudioFile: TAudioFile;
            Error: TNempAudioError;
            Important: Boolean;
            constructor create(aAction: TAudioFileAction; aFile: TAudioFile;
                aErr: TNempAudioError; aImportant: Boolean);
    end;


    TAudioFileCompare = function(a1,a2: TAudioFile): Integer;
    TSortDirection = (sd_Ascending, sd_Descending);

    TCompareRecord = record
        Comparefunction: TAudioFileCompare;
        Direction: TSortDirection;
        Tag: Integer;
    end;
    

const
      // GAD_xxx: Flags for GetAudioData-Methods
      // GAD_Cover  = 1;
      // 4.12: GAD_Cover is not used anymore. When we want to scan a file for coverart,
      // it is done within the method Medienbib.InitCover -> there is also done the "SaveToID"-stuff
      // (which was kinda misplacec in AudioFile.GetAudioData anyway ...)
      GAD_Rating = 2;  // !!!!  ignored by the subfunctions
      GAD_CDDB   = 4;
      GAD_NOLYRICS = 8;
      // note for future extensions:
      // this is planned as bitmasks, so use 4,8,16,32,.. for additional flags

      // Flags for setting ReplayGainValues
      RG_SetTrack = 1;
      RG_SetAlbum = 2;
      RG_SetBoth  = 3; // = RG_SetTrack OR RG_SetAlbum
      RG_ClearTrack = 4;
      RG_ClearAlbum = 8;
      RG_ClearBoth = 12; // = RG_ClearTrack OR RG_ClearAlbum

      // SAD_xxx Flags for SetAudioData-Methods
      //SAD_None     = 0;   // Do not Update Informatin in the file
      //SAD_Existing = 1;  // Update only existing Tag (note: v2 Tag has to be created!)
      //SAD_Both     = 2;  // Update both (v1 an v2)-Tags

      // property-IDs for saving/loading
      // general format in the gmp/npl-files
      // 1Byte ID
      // Data according to ID. Byte, Integer, String, ..
      MP3DB_PFAD        = 0;
      MP3DB_ARTIST      = 1;
      MP3DB_TITEL       = 2;
      MP3DB_ALBUM       = 3;
      MP3DB_DAUER       = 4;
      MP3DB_BITRATE     = 5;
      MP3DB_VBR         = 6;
      MP3DB_CHANNELMODE = 7;
      MP3DB_SAMPLERATE  = 8;
      MP3DB_FILESIZE    = 10;
      MP3DB_DATUM       = 11;
      MP3DB_TRACK       = 12;  // Byte
      MP3DB_TRACK_INT   = 13;  // Integer, Nemp 4.13
      //---
      MP3DB_KATEGORIE   = 20;  // this was used in "Gausis mp3 Verwaltung"
                               // (something like Nemp 0.1)
      MP3DB_KOMMENTAR   = 21;
      MP3DB_YEAR        = 22;
      MP3DB_GENRE       = 23;
      MP3DB_GENRE_STR   = 26;  //$1A
      MP3DB_LYRICS      = 24;
      MP3DB_ID3KOMMENTAR = 25;
      MP3DB_COVERID = 27;

      //MP3DB_DUMMY_Byte1  = 28;
      MP3DB_RATING = 28;

      MP3DB_CUEPRESENT   = 30;

      // some dummy IDs for future use.
      // Ints are Integer, Bytes are Bytes, Texts are strings
      // note: some of them are already in use
      //MP3DB_DUMMY_Byte2  = 29;
      MP3DB_FAVORITE  = 29;

      //MP3DB_DUMMY_Int1   = 30;
      // MP3DB_DUMMY_Int2   = 31;
      MP3DB_PLAYCOUNTER  = 31;
      // MP3DB_DUMMY_Int3   = 32;
      MP3DB_DRIVE_ID   = 32; // new in 4.13: The ID of the drive, needed for changing the drive letter properly

      //MP3DB_DUMMY_Text1  = 33;
      MP3DB_LASTFM_TAGS  = 33;
      //MP3DB_DUMMY_Text2  = 34;
      MP3DB_CD = 34;    // new in 4.5 (Part of aSet)

      //MP3DB_DUMMY_Text3  = 35;
      MP3DB_ALBUMGAIN = 35;
      MP3DB_TRACKGAIN = 36;

      MP3DB_ALBUMPEAK = 37;
      MP3DB_TRACKPEAK = 38;


      // 42 marked the end of an AudioFile (until Nemp 4.12)
      MP3DB_ENDOFINFO = 42;

      // Some Constant-Arrays
      // Probably there exists better ways of doing the stuff, where this is used
      // - but these lines are one of the first lines ever written for this program ;)
      Mp3db_Samplerates: Array[0..9] of String
            = (' 8.0','11.0','12.0','16.0','22.0','24.0','32.0','44.1','48.0','N/A ');
      Nemp_Samplerates_Int: Array[0..9] of Integer
            = ( 8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000, -1);
      Mp3db_Modes:  Array[0..5] of String
            = ('S ','JS','DC','M ','--', 'X');
      Nemp_Modes_Int: Array[0..5] of Integer
            = (2,2,2,1,-1, 0);
      Mp3DB_ExtendedModes : Array[0..5] of String =('Stereo', 'Joint-Stereo', 'Dual-Channel', 'Mono', '', 'Multi');

      AUDIOFILE_UNKOWN = '<N/A>';

      // Used for parsing cue-sheets
      CUE_ID_FILE      = 0;
      CUE_ID_PERFORMER = 1;
      CUE_ID_TITLE     = 2;
      CUE_ID_TRACK     = 3;
      CUE_ID_INDEX     = 4;
      CUE_ID_UNKNOWN   = 5;

      // some helpers for cue-sheets
      function GetCueID(aString: String): Byte;
      function GetFileNameFromCueString(aString: String):String;



function GetMp3Details(filename:UnicodeString;
      var mpeginfo:Tmpeginfo;
      var ID3v2Tag: TID3v2Tag;
      var id3v1tag:Tid3v1tag): TMp3Error;

function AudioToNempAudioError(aError: TAudioError): TNempAudioError;
function Mp3ToAudioError(aError: TMp3Error): TNempAudioError;
function CDToAudioError(aError: TCddaError): TNempAudioError;

function UnKownInformation(aString: String): Boolean;

procedure SetCDDADefaultInformation(af: TAudioFile);

function GetAudioTypeFromFilename(aFilename: String): TAudioType;

implementation

uses Dialogs, CoverHelper, Nemp_RessourceStrings, SystemHelper, NempFileUtils;

 {$I-}

function AudioToNempAudioError(aError: TAudioError): TNempAudioError;
begin
    case aError of
        FileERR_None          : result := AUDIOERR_None ;
        FileERR_NoFile        : result := AUDIO_FILEERR_NoFile ;
        FileERR_FileCreate    : result := AUDIO_FILEERR_FOpenCrt;
        FileERR_FileOpenR     : result := AUDIO_FILEERR_FOpenR ;
        FileERR_FileOpenRW    : result := AUDIO_FILEERR_FOpenRW;
        //FileERR_FileOpenW   : result := AUDIO_FILEERR_FOpenW ;
        Mp3ERR_StreamRead     : result := AUDIO_FILEERR_SRead  ;
        Mp3ERR_StreamWrite    : result := AUDIO_FILEERR_SWrite ;
        Mp3ERR_Cache          : result := AUDIO_ID3ERR_Cache;
        Mp3ERR_NoTag          : result := AUDIOERR_None;      // Nemp does not handle this as "Error"
        Mp3ERR_Invalid_Header : result := AUDIO_ID3ERR_Invalid_Header;
        Mp3ERR_Compression    : result := AUDIO_ID3ERR_Compression;
        Mp3ERR_Unclassified   : result := AUDIO_ID3ERR_Unclassified;
        MP3ERR_NoMpegFrame    : result := AUDIO_MPEGERR_NoFrame;

        OVErr_InvalidFirstPageHeader    : result := AUDIO_OVErr_InvalidFirstPageHeader ;
        OVErr_InvalidFirstPage          : result := AUDIO_OVErr_InvalidFirstPage       ;
        OVErr_InvalidSecondPageHeader   : result := AUDIO_OVErr_InvalidSecondPageHeader;
        OVErr_InvalidSecondPage         : result := AUDIO_OVErr_InvalidSecondPage      ;
        OVErr_CommentTooLarge           : result := AUDIO_OVErr_CommentTooLarge        ;
        OVErr_BackupFailed              : result := AUDIO_OVErr_BackupFailed           ;
        OVErr_DeleteBackupFailed        : result := AUDIO_OVErr_DeleteBackupFailed     ;
        OVErr_RemovingNotSupported      : result := AUDIOERR_Unkown; // Nemp does not permit this

        FlacErr_InvalidFlacFile     : result := AUDIO_FlacErr_InvalidFlacFile  ;
        FlacErr_MetaDataTooLarge    : result := AUDIO_FlacErr_MetaDataTooLarge ;
        FlacErr_BackupFailed        : result := AUDIO_OVErr_BackupFailed       ;
        FlacErr_DeleteBackupFailed  : result := AUDIO_OVErr_DeleteBackupFailed ;
        FlacErr_RemovingNotSupported: result := AUDIOERR_Unkown; // Nemp does not permit this

        ApeErr_InvalidApeFile       : result := AUDIO_ApeErr_InvalidApeFile;
        ApeErr_InvalidTag           : result := AUDIO_ApeErr_InvalidApeTag;
        ApeErr_NoTag                : result := AUDIOERR_None;   // Nemp does not handle this as "Error"

        WmaErr_WritingNotSupported  : result := AUDIOERR_UnsupportedMediaFile; // Nemp does not permit this
        WavErr_WritingNotSupported  : result := AUDIOERR_UnsupportedMediaFile; // Nemp does not permit this

        FileErr_NotSupportedFileType: result := AUDIOERR_UnsupportedMediaFile;

        M4aErr_Invalid_TopLevelAtom : result := AUDIO_M4aErr_Invalid_TopLevelAtom ;
        M4aErr_Invalid_UDTA         : result := AUDIO_M4aErr_Invalid_UDTA         ;
        M4aErr_Invalid_METAVersion  : result := AUDIO_M4aErr_Invalid_METAVersion  ;
        M4aErr_Invalid_MDHD         : result := AUDIO_M4aErr_Invalid_MDHD         ;
        M4aErr_Invalid_STSD         : result := AUDIO_M4aErr_Invalid_STSD         ;
        M4aErr_Invalid_STCO         : result := AUDIO_M4aErr_Invalid_STCO         ;
        M4aErr_Invalid_DuplicateUDTA: result := AUDIO_M4aErr_Invalid_DuplicateUDTA;
        M4aErr_Invalid_DuplicateTRAK: result := AUDIO_M4aErr_Invalid_DuplicateTRAK;

        M4aErr_RemovingNotSupported : result := AUDIOERR_Unkown; // Nemp does not permit this

    else
        result := AUDIOERR_Unkown ;
    end;
end;

function Mp3ToAudioError(aError: TMp3Error): TNempAudioError;
begin
    case aError of
        MP3ERR_None              : result := AUDIOERR_None ;
        MP3ERR_NoFile            : result := AUDIO_FILEERR_NoFile ;
        MP3ERR_FOpenCrt          : result := AUDIO_FILEERR_FOpenCrt;
        MP3ERR_FOpenR            : result := AUDIO_FILEERR_FOpenR ;
        MP3ERR_FOpenRW           : result := AUDIO_FILEERR_FOpenRW;
        MP3ERR_FOpenW            : result := AUDIO_FILEERR_FOpenW ;
        MP3ERR_SRead             : result := AUDIO_FILEERR_SRead  ;
        MP3ERR_SWrite            : result := AUDIO_FILEERR_SWrite ;
        ID3ERR_Cache             : result := AUDIO_ID3ERR_Cache;
        ID3ERR_NoTag             : result := AUDIOERR_None;      // !!
        ID3ERR_Invalid_Header    : result := AUDIO_ID3ERR_Invalid_Header;
        ID3ERR_Compression       : result := AUDIO_ID3ERR_Compression;
        ID3ERR_Unclassified      : result := AUDIO_ID3ERR_Unclassified;
        MPEGERR_NoFrame          : result := AUDIO_MPEGERR_NoFrame;
    else
        result := AUDIOERR_Unkown ;
    end;
end;

function CDToAudioError(aError: TCddaError): TNempAudioError;
begin
    case aError of
      cddaErr_None               : result := AUDIOERR_None;
      cddaErr_invalidPath        : result := AUDIO_FILEERR_NoFile;
      cddaErr_invalidDrive       : result := AUDIO_FILEERR_NoFile;
      cddaErr_invalidTrackNumber : result := AUDIO_FILEERR_NoFile;
      cddaErr_DriveNotReady      : result := AUDIOERR_DriveNotReady;
      cddaErr_NoAudioTrack       : result := AUDIOERR_NoAudioTrack;
    else
        result := AUDIOERR_Unkown ;
    end;
end;

function UnKownInformation(aString: String): Boolean;
begin
    result := (trim(aString) = '') or (aString = AUDIOFILE_UNKOWN);
end;

procedure SetCDDADefaultInformation(af: TAudioFile);
begin
    // fixed values
    af.fSamplerateIDX  := 7; // 44.1 kHz
    af.fChannelModeIDX := 0; // Stereo
    af.Bitrate := 1411;   // CD audio is always 44100hz stereo 16-bit. That is 176400 bytes per second = 1411200 kbps
end;

function GetAudioTypeFromFilename(aFilename: String): TAudioType;
begin
    // determine AudioType
    if (pos('://', aFilename) > 0) then
    begin
        if AnsiStartsText('cda', aFilename)
            or AnsiStartsText('cdda', aFilename)
        then
            result := at_CDDA     // CD-Audio
        else
            result := at_Stream;  // Webradio
    end else
    begin
        if AnsiLowerCase(ExtractFileExt(aFilename)) = '.cda' then
            result := at_CDDA         // CD-Audio (.cda-File)
        else
            result := at_File         // File
    end;
end;



 { TTag }

constructor TTag.Create(aKey: String; aTranslate: Boolean);
begin
    inherited create;
    AudioFiles := TObjectList.Create(False);
    if aTranslate then
        fKey := aKey // for the default "your library"
    else
        fKey := AnsiLowercase(aKey);
    fIsAutoTag := False;
    fTranslate := aTranslate;
    BreadCrumbIndex := High(Integer);
end;

destructor TTag.Destroy;
begin
    AudioFiles.Free;
    inherited;
end;

function TTag.GetCount: Integer;
begin
    result := AudioFiles.Count;
end;



{
    --------------------------------------------------------
    GetMp3Details
      Read ID3v1Tag,
      Read ID3v2Tag,
      Read Mpeg-Info from file
    --------------------------------------------------------
}
function GetMp3Details(filename: UnicodeString;
    var mpeginfo:Tmpeginfo;
    var ID3v2Tag: TID3v2Tag;
    var id3v1tag:Tid3v1tag): TMp3Error;
var
    Stream: TFileStream;
    tmp: TMP3Error;
begin
    //result := MP3ERR_None;
    try
        Stream := TFileStream.Create(filename, fmOpenRead or fmShareDenyWrite);
        try
            result := id3v1tag.ReadFromStream(Stream);
            Stream.Seek(0, sobeginning);
            tmp := id3v2tag.ReadFromStream(Stream);
            if id3v2Tag.exists then
                Stream.Seek(id3v2tag.size, soBeginning)
            else
                Stream.Seek(0, sobeginning);
            if (tmp <> MP3ERR_None) and ((result = ID3ERR_NoTag) or (result = MP3ERR_None)) then
                result := tmp;

            tmp := mpeginfo.LoadFromStream(Stream);
            if (tmp <> MP3ERR_None) then
                result := tmp;
        finally
            Stream.free;
        end;
    except
        // nothing here
        // if FileStream.Create throws an Exception just do nothing
        // this method is called too often. ;-)
        result := MP3ERR_FOpenR;
    end;
end;


{
    --------------------------------------------------------
    Basic Class-Stuff.
    Create, Destroy, Assign
    --------------------------------------------------------
}
constructor TAudioFile.create;
begin
    inherited create;
    Duration := 0;
    fBitrate := 160;
    fChannelmodeIDX := 1; // JS;
    fSamplerateIDX := 7 ; // = 44.1Hz
    FileIsPresent := True;
    Genre := 'Other';
    Year := '';
    LastPlayed := 0;
    Track := 0;
    CD := '';
    coverID := '';
    fRating := 0;
    fFileAge := 40300;    // this is May 2nd, 2010, so all files from Nemp3 will appear as may 2010
    ID3TagNeedsUpdate := False;
    TrackPeak := 1;
    AlbumPeak := 1;
end;
destructor TAudioFile.Destroy;
begin
  if assigned(CueList) then
  begin
      // clear and free cuelist if present
      CueList.Clear;
      CueList.Free;
  end;
  if assigned(fTagList) then
      fTagList.Free;

  inherited destroy;
end;

procedure TAudioFile.AddCopyToList(aList: TObjectList);
var newFile: TAudioFile;
begin
    newFile := TAudioFile.Create;
    newFile.Assign(self);
    aList.Add(newFile);
end;

procedure TAudioFile.Assign(aAudioFile: TAudioFile);
begin
    Description        := aAudioFile.Description         ;
    fFileSize          := aAudioFile.fFileSize           ;
    fFileAge           := aAudioFile.fFileAge            ;
    Duration           := aAudioFile.Duration            ;
    fBitrate           := aAudioFile.fBitrate            ;
    fvbr               := aAudioFile.fvbr                ;
    fChannelModeIDX    := aAudioFile.fChannelModeIDX     ;
    fSamplerateIDX     := aAudioFile.fSamplerateIDX      ;
    FileIsPresent      := aAudioFile.FileIsPresent       ;
    Titel              := aAudioFile.Titel               ;
    Artist             := aAudioFile.Artist              ;
    Album              := aAudioFile.Album               ;
    Genre              := aAudioFile.Genre               ;
    Year               := aAudioFile.Year                ;
    Track              := aAudioFile.Track               ;
    CD                 := aAudioFile.CD                  ;
    Comment            := aAudioFile.Comment             ;
    Lyrics             := aAudioFile.Lyrics              ;
    CoverID            := aAudioFile.CoverID             ;
    Rating             := aAudioFile.Rating              ;
    PlayCounter        := aAudioFile.PlayCounter         ;
    fAudioType         := aAudioFile.fAudioType          ;
    Pfad               := aAudioFile.Pfad                ;
    RawTagLastFM       := aAudioFile.RawTagLastFM        ;
    Favorite           := aAudioFile.fFavorite           ;
    TrackGain          := aAudioFile.TrackGain           ;
    AlbumGain          := aAudioFile.AlbumGain           ;
    TrackPeak          := aAudioFile.TrackPeak           ;
    AlbumPeak          := aAudioFile.AlbumPeak           ;

end;
procedure TAudioFile.AssignLight(aAudioFile: TAudioFile);
begin
    Description        := aAudioFile.Description         ;
    fFileSize          := aAudioFile.fFileSize           ;
    fFileAge           := aAudioFile.fFileAge            ;
    Duration           := aAudioFile.Duration            ;
    fBitrate           := aAudioFile.fBitrate            ;
    fvbr               := aAudioFile.fvbr                ;
    fChannelModeIDX    := aAudioFile.fChannelModeIDX     ;
    fSamplerateIDX     := aAudioFile.fSamplerateIDX      ;
    FileIsPresent      := aAudioFile.FileIsPresent       ;

    Titel              := aAudioFile.Titel               ;
    Artist             := aAudioFile.Artist              ;
    Album              := aAudioFile.Album               ;
    Genre              := aAudioFile.Genre               ;
    Year               := aAudioFile.Year                ;
    Track              := aAudioFile.Track               ;
    CD                 := aAudioFile.CD                  ;
    Comment            := aAudioFile.Comment             ;
    // No Lyrics here!
    CoverID            := aAudioFile.CoverID             ;
    Rating             := aAudioFile.Rating              ;
    PlayCounter        := aAudioFile.PlayCounter         ;
    fAudioType         := aAudioFile.fAudioType          ;
    Pfad               := aAudioFile.Pfad                ;
    Favorite           := aAudioFile.fFavorite           ;
    TrackGain          := aAudioFile.TrackGain           ;
    AlbumGain          := aAudioFile.AlbumGain           ;
    TrackPeak          := aAudioFile.TrackPeak           ;
    AlbumPeak          := aAudioFile.AlbumPeak           ;
end;

{
    --------------------------------------------------------
    SetNewDriveChar
    Change x:\[...]\mySong.mp3 to y:\[...]\mySong.mp3.
    If the Path starts with "\" (i.e. "\\"), nothing is done
    --------------------------------------------------------
}
procedure TAudioFile.SetNewDriveChar(aChar: Char);
begin
  if length(FStrings[siOrdner]) > 1 then
  begin
    if FStrings[siOrdner][1] <> '\' then
        FStrings[siOrdner][1] := aChar;
  end;
end;


{
    --------------------------------------------------------
    ReCheckExistence
    Check, whether the file exist, cdda is present, ..
           and set FileIsPresent again
           used for striking out non existing files
    --------------------------------------------------------
}
function TAudioFile.ReCheckExistence: Boolean;
begin
    case AudioType of
        at_Undef: FileIsPresent := False;
        at_File: FileIsPresent := FileExists(Pfad);
        at_Stream: FileIsPresent := True;

        at_CDDA: begin
            // more todo
            FileIsPresent := True;
        end;
        at_CUE: FileIsPresent := True;
    end;

    result := FileIsPresent;
end;

{
    --------------------------------------------------------
    Setter and Getter for Path
    --------------------------------------------------------
}
function TAudioFile.GetPath: UnicodeString;
begin
    case fAudioType of
        at_Undef  : result := fStrings[siOrdner];
        at_File   : result := IncludeTrailingPathDelimiter(FStrings[siOrdner]) {+ '\'} + Dateiname ;
        at_Stream : result := fStrings[siOrdner];
        at_CDDA   : if FStrings[siDateiname] = '' then
                        result := fStrings[siOrdner]
                    else
                        result := IncludeTrailingPathDelimiter(fStrings[siOrdner]) {+ '\'} + Dateiname;
        at_CUE    : result := IncludeTrailingPathDelimiter(FStrings[siOrdner]) {+ '\'} + Dateiname ;
    end;
end;

procedure TAudioFile.SetPath(const Value: UnicodeString);
begin
    if fAudioType = at_Undef then
        fAudioType := GetAudioTypeFromFilename(Value);

    case fAudioType of
        at_File: begin
            FStrings[siOrdner] := ExtractFileDir(Value); // now without the last '\'  // ExtractFilePath(Value);//
            FStrings[siDateiname] := ExtractFileName(Value);
        end;

        at_Stream: begin
            FStrings[siOrdner] := Value;
            FStrings[siDateiname] := '';
        end;

        at_CUE : begin
            FStrings[siOrdner] := ExtractFileDir(Value); // ExtractFilePath(Value);
            FStrings[siDateiname] := ExtractFileName(Value);
        end;

        at_CDDA: begin
            if AnsiLowerCase(ExtractFileExt(Value)) = '.cda' then
            begin // we have a "file" here
                FStrings[siOrdner] := ExtractFileDir(Value); //ExtractFilePath(Value);
                FStrings[siDateiname] := ExtractFileName(Value);
            end else
            begin
                // no cda-File
                FStrings[siOrdner] := Value;
                FStrings[siDateiname] := '';
            end;
        end;
    end;
end;

function TAudioFile.fGetIsFile: Boolean;
begin
    result := fAudioType = at_File;
end;

function TAudioFile.fGetIsLocalFile: Boolean;
begin
    result := NOT AnsiStartsText('\', self.FStrings[siOrdner])
end;

function TAudioFile.fGetIsStream: Boolean;
begin
    result := fAudioType = at_Stream;
end;

function TAudioFile.fGetIsCDDA: Boolean;
begin
    result := fAudioType = at_CDDA;
end;

function TAudioFile.fGetRoundedRating: Double;
//var base: Integer;
begin
    // unit RatingCtrls
    result := GetRoundedRating(fRating);
end;

function TAudioFile.GetHint(naArtist, naTitle, naAlbum: Integer): UnicodeString;
begin
    case fAudioType of
        at_Undef: result := ''; // 'ERROR: UNDEFINED AUDIOTYPE';

        at_File: begin
            result :=
                   Format(' %s: %s'        , [(AudioFileProperty_Artist)    ,GetReplacedArtist(naArtist)]) + #13#10
                 + Format(' %s: %s'        , [(AudioFileProperty_Title)     ,GetReplacedTitle(naTitle)]) + #13#10
                 + Format(' %s: %s'        , [(AudioFileProperty_Album)     ,GetReplacedAlbum(naAlbum)]);

            if Track <> 0 then
                result := result + Format(' (%s %d)', [AudioFileProperty_Track, Track]) + #13#10
            else
                result := result + #13#10;

            result := result
                 + Format(' %s: %s'        , [(AudioFileProperty_Duration)  ,SekIntToMinStr(Duration)]) + #13#10
                 + Format(' %s: %s kbit/s' , [(AudioFileProperty_Bitrate)   ,IntTostr(Bitrate)]) + #13#10
                 + Format(' %s: %s MB'     , [(AudioFileProperty_Filesize)  ,FloatToStrF((Size / 1024 / 1024),ffFixed,4,2)]) + #13#10
                 + Format(' %s: %s'        , [(AudioFileProperty_Directory) ,Ordner]) + #13#10
                 + Format(' %s: %s'        , [(AudioFileProperty_Filename)  ,Dateiname]);


            result := result + #13#10
                            + ' ' + Format(Audiofile_RatingHint, [FloatToStrF(RoundedRating,ffFixed,4,1)]);

            if (PlayCounter > 0) then
                result := result + ', '
                            + Format(Audiofile_PlayCounterHint, [PlayCounter]);

            if (Not IsZero(TrackGain)) and (Not isZero(AlbumGain)) then
                result := result + #13#10 + Format(Audiofile_ReplayGain_Album, [TrackGain, AlbumGain])
            else
                if (Not IsZero(TrackGain)) then
                    result := result + #13#10 + Format(Audiofile_ReplayGain_Track, [TrackGain])
        end;

        at_Stream: begin
            result := ' ' + (AudioFileProperty_Webstream) + #13#10
                 + Format(' %s: %s', [(AudioFileProperty_Name), Description]) + #13#10
                 + Format(' %s: %s', [(AudioFileProperty_URL) , Pfad])
        end;

        at_cue: begin
            result := 'Cue-Sheet ' + #13#10 //+ Data^.FAudioFile.Dateiname + #13#10
                  + Format(' %s: %s'        , [(AudioFileProperty_Artist)    ,GetReplacedArtist(naArtist)]) + #13#10
                  + Format(' %s: %s'        , [(AudioFileProperty_Title)     ,GetReplacedTitle(naTitle)])+ #13#10
                  + Format(' %s: %s'        , [(AudioFileProperty_Directory) ,Ordner]) + #13#10
                  + Format(' %s: %s'        , [(AudioFileProperty_Filename)  ,Dateiname]);
        end;

        at_CDDA: begin
            if trim(Artist) = '' then
                result :=
                       'CD-Audio, '
                     + Format(' %s %d' , [AudioFileProperty_Track, Track]) + #13#10
                     + Format(' %s: %s', [(AudioFileProperty_Duration)  ,SekIntToMinStr(Duration)])
            else
                result :=
                       Format(' %s: %s'        , [(AudioFileProperty_Artist)    , Artist]) + #13#10
                     + Format(' %s: %s'        , [(AudioFileProperty_Title)     , Titel]) + #13#10
                     + Format(' %s: %s'        , [(AudioFileProperty_Album)     , Album]) + #13#10
                     // we have always a Track here ;-)
                     + Format(' %s %d', [AudioFileProperty_Track, Track]) + #13#10
                     + Format(' %s: %s'        , [(AudioFileProperty_Duration)  ,SekIntToMinStr(Duration)]) + #13#10
                     + 'CD-Audio';
        end;
    end;
end;

function TAudioFile.GetArtistForVST(ReplaceValue: Integer): String;
begin
    case self.fAudioType of
        at_Undef: result := 'Error: Undefined AudioType!';
        at_File: result := GetReplacedArtist(ReplaceValue);
        at_Stream: result := Format('(%s)', [AudioFileProperty_Webstream]);
        at_CDDA: result := GetReplacedArtist(ReplaceValue);
    end;
end;
function TAudioFile.GetTitleForVST(ReplaceValue: Integer): String;
begin
    case self.fAudioType of
        at_Undef: result := 'Error: Undefined AudioType!';
        at_File: result := GetReplacedTitle(ReplaceValue);
        at_Stream: result := Format('(%s)', [AudioFileProperty_Webstream]);
        at_CDDA: result := GetReplacedTitle(ReplaceValue);
    end;
end;
function TAudioFile.GetAlbumForVST(ReplaceValue: Integer): String;
begin
    case self.fAudioType of
        at_Undef  : result := 'Error: Undefined AudioType!';
        at_File   : result := GetReplacedAlbum(ReplaceValue);
        at_Stream : result := Format('(%s)', [AudioFileProperty_Webstream]);
        at_CDDA   : result := GetReplacedAlbum(ReplaceValue);
    end;
end;
function TAudioFile.GetBitrateForVST: String;
begin
    if Bitrate > 0 then
    begin
        if vbr then
            result := inttostr(Bitrate) + ' kbit/s' + ' (vbr)'
        else
            result := inttostr(Bitrate) + ' kbit/s';
    end
    else
        result := '-?-';
end;

function TAudioFile.GetDurationForVST: String;
begin
    case fAudioType of
        at_Undef  : result := 'Error: Undefined AudioType!';
        at_File   : result := SekIntToMinStr(Duration);
        at_Stream : result := '(inf)';
        at_CDDA   : result := SekIntToMinStr(Duration);
    end;
end;


function TAudioFile.GetReplaceString(ReplaceValue: Integer): String;
begin
    case ReplaceValue of
        0: result := ''; // Empty String
        1: result := AUDIOFILE_UNKOWN;
        2: result := ChangeFileExt(Dateiname, '');
        3: result := ExtractFileName(ExcludeTrailingPathDelimiter(Ordner));
        4: result := Ordner;
        5: result := Pfad;
    else
        result := '';
    end;
end;
function TAudioFile.GetReplacedArtist(ReplaceValue: Integer): String;
begin
    if trim(Artist) = '' then
        result := GetReplaceString(ReplaceValue)
    else
        result := Artist;
end;
function TAudioFile.GetReplacedTitle(ReplaceValue: Integer): String;
begin
    if trim(Titel) = '' then
        result := GetReplaceString(ReplaceValue)
    else
        result := Titel;
end;
function TAudioFile.GetReplacedAlbum(ReplaceValue: Integer): String;
begin
    if trim(Album) = '' then
        result := GetReplaceString(ReplaceValue)
    else
        result := Album;
end;


function TAudioFile.IsValidArtist: Boolean;
begin
    result := trim(Artist) <> '';
end;

function TAudioFile.IsValidTitle : Boolean;
begin
    result := trim(Titel) <> '';
end;

function TAudioFile.IsValidAlbum : Boolean;
begin
    result := trim(Album) <> '';
end;

function TAudioFile.IsValidYear  : Boolean;
begin
    result := (trim(Year) <> '')
              AND (trim(Year) <> '0');
end;

function TAudioFile.IsValidGenre : Boolean;
begin
    result := trim(Genre) <> '';
end;



{
    --------------------------------------------------------
    Setter and Getter for String Values
    Note to self: Eventually obsolete soon
    --------------------------------------------------------
}
function TAudioFile.GetString(Index: TAudioFileStringIndex): UnicodeString;
begin
    if Index = siFileAge then
        result := FormatDateTime('mmmm yyyy' , fFileAge)
    else
        result := FStrings[Index];
end;
procedure TAudioFile.SetString(Index: TAudioFileStringIndex; const Value: UnicodeString);
begin
    FStrings[Index] := Value;
end;

function TAudioFile.GetFileAgeSortString: String;
begin
    result := FormatDateTime('yyyymm', fFileAge);
end;



function TAudioFile.fGetPlaylistTitleString: UnicodeString;
begin
    case fAudioType of
        at_Undef  : result := '';

        at_File, at_CDDA, at_CUE: begin
            if UnKownInformation(Artist) then
                result := NonEmptyTitle
            else
                result := Artist + ' - ' + NonEmptyTitle;
        end;

        at_Stream : begin
            if (artist <> '') and (titel <> '') then  // could be the case on remote ogg-files (through "DoOggMeta")
                result := Artist + ' - ' + NonEmptyTitle
            else
            begin
                result := Description;
                if (titel <> '') and (titel <> pfad) then
                    result := result + ' (' + titel + ')';
            end;
        end;
    end;

    if result = '' then
        result := Pfad;
end;

{
    --------------------------------------------------------
    fGetNonEmptyTitle
    Needed in Nemp 4.1: if no title-information is found in the Meta-Tags,
    the title-field will be left blank.
    But sometimes we NEED some "title".
    --------------------------------------------------------
}
function TAudioFile.fGetNonEmptyTitle: UnicodeString;
begin
    if UnKownInformation(Titel) then
        result := ChangeFileExt(Dateiname, '')
    else
        result := Titel;

    if result = '' then // possible at CD-DA, as there is no filename? (Check, if cdda-support is complete. ;-))
    begin
        case fAudioType of
            at_Undef,
            at_File,
            at_Stream,
            at_CUE : result := Pfad;
            at_CDDA: Result := 'CD-Audio, Track ' + IntToStr(Track);
        end;

    end;
end;

{
    --------------------------------------------------------
    fGetProperFilename
    Used for Copying the Playlist to USB (or whatever)
    Only real files can be copied, no cdda, no webstreams
    --------------------------------------------------------
}
function TAudioFile.fGetProperFilename: UnicodeString;
begin
    case fAudioType of
        at_Undef,
        at_Stream,
        at_CDDA: result := '//';  // invalid Filename ;-)

        at_File: begin
              if UnKownInformation(Artist) then
              begin
                  //if NonEmptyTitle <> Dateiname then
                      result := NonEmptyTitle + '.' + self.Extension
                  //else
                  //    result := Dateiname;
              end
              else
              begin
                  //if NonEmptyTitle <> Dateiname then
                      result := Artist + ' - ' + NonEmptyTitle + '.' + self.Extension
                  //else
                  //    result := Artist + ' - ' + NonEmptyTitle;
              end;
              result := ReplaceForbiddenFilenameChars(result);
        end;
    end;
    if result = '' then
        result := ReplaceForbiddenFilenameChars(Dateiname);
end;

function TAudioFile.fGetTagList: TObjectList;
begin
    if not Assigned(fTagList) then
        fTagList := TObjectList.Create(False);
    result := fTagList;
end;

(*
function TAudioFile.GetTagDisplayString(allowEdit: Boolean): String;
begin
    if trim(String(RawTagLastFM)) <> '' then
        result := StringReplace(Trim(String(RawTagLastFM)), #13#10, ', ', [rfreplaceAll])
    else
    begin
        if HasSupportedTagFormat then
        begin
            if allowEdit then
                result := Tags_AddTags
            else
                result := ''; // Tags_NoTagsAccessDenied;
        end
        else
            result := ''; //Tags_AddTagsNotPossible;
    end;
end;
*)

{
    --------------------------------------------------------
    Getter for ChannelMode
    --------------------------------------------------------
}
function TAudioFile.GetChannelMode: String;
begin
    result := Mp3DB_ExtendedModes[fChannelModeIDX];
end;
function TAudioFile.GetChannelModeShort: String;
begin
    result := Mp3db_Modes[fChannelModeIDX];
end;



{
    --------------------------------------------------------
    Getter for Samplerate
    First version is used in Detail-window
    Second is used in main VST
    --------------------------------------------------------
}
function TAudioFile.GetSamplerate: String;
begin
    result := Mp3db_Samplerates[fSamplerateIDX] + ' kHz';
end;
function TAudioFile.GetSamplerateShort: String;
begin
    result := Mp3db_Samplerates[fSamplerateIDX];
end;
{
    --------------------------------------------------------
    "Setter" for Samplerate.
    Used by the bass.dll to correct the value
    (e.g. on files with unknown tag-structure)
    --------------------------------------------------------
}
procedure TAudioFile.SetSampleRate(aRate: Integer);
begin
    case aRate of
        8000 : fSamplerateIDX := 0;
        11025: fSamplerateIDX := 1;
        12000: fSamplerateIDX := 2;
        16000: fSamplerateIDX := 3;
        22050: fSamplerateIDX := 4;
        24000: fSamplerateIDX := 5;
        32000: fSamplerateIDX := 6;
        44100: fSamplerateIDX := 7;
        48000: fSamplerateIDX := 8;
    else
        fSamplerateIDX := 9;
    end;
end;
{
    --------------------------------------------------------
    Getter for Extension
    (modified version of SysUtils.ExtractFileExt - we dont need the "." here)
    --------------------------------------------------------
}
function TAudioFile.fGetExtension: String;
var I: Integer;
begin
    I := LastDelimiter('.' + PathDelim + DriveDelim, Dateiname) + 1;
    if (I > 1) and (Dateiname[I-1] = '.') then
        Result := Copy(Dateiname, I, MaxInt)
    else
        Result := '';
end;

{
    --------------------------------------------------------
    Getter for LyricsExisting
    --------------------------------------------------------
}
function TAudioFile.fGetLyricsExisting: Boolean;
begin
  result := flyrics <> '';
end;

{
    --------------------------------------------------------
    GetAudioData, main method of this class
    Flags are only used in mp3/ogg/flac-files.
    Notes:
      * Covers contained in mp3-Files are recognized
        If no Cover in the id3tag was found, the MedieLibrary
        will call another "GetCover"-method. This is done not in this
        class, as the filesearching will give the same result on every
        file in the same directory. Doing this outside this class
        would be much faster.
        However, sometimes it is not wanted to read the cover from the
        file. In this case you should NOT add the Flag GAD_Cover, otherwise
        this flag should be used.
      * The Medialibrary can manage ratings without saving it to the files.
        When the user presses "F5" to refresh some files, with a unsaved
        Library-rating, these ratings will be lost. So ratings are only read,
        if flag GAD_Rating is set AND the current rating is equal to 0
        (i.e. undefined).
        If the user wants to reset the ratings: Use "reset ratings".
    --------------------------------------------------------
}
function TAudioFile.GetAudioData(filename: UnicodeString; Flags: Integer = 0): TNempAudioError;
var MainFile: TGeneralAudioFile;
    fs: TFileStream;
begin
  // result := AUDIOERR_Unkown; // default value

  Pfad := filename; // Set Path and determine Audiotype (file, stream, CD-Audio)

  case fAudioType of
      at_File: begin
          try
              FileIsPresent := FileExists(filename);
              if not FileIsPresent then
              begin
                  SetUnknown;
                  result := AUDIO_FILEERR_NoFile;
              end else
              begin
                  fFileAge := GetFileCreationDateTime(filename);

                  MainFile := TGeneralAudioFile.Create(filename);
                  try
                      result := AudioToNempAudioError(MainFile.LastError);

                      // get detailed information (format-specific)
                      case MainFile.FileType of
                          at_Invalid: SetUnknown;
                          at_Mp3:  GetMp3Info(MainFile.MP3File, filename, Flags);
                          at_Ogg: GetOggInfo(Mainfile.OggFile, Flags);
                          at_Flac: GetFlacInfo(MainFile.FlacFile, Flags);
                          at_M4A: GetM4AInfo(MainFile.M4AFile, Flags);
                          at_Monkey,
                          at_WavPack,
                          at_MusePack,
                          at_OptimFrog,
                          at_TrueAudio: GetExoticInfo(MainFile.BaseApeFile, MainFile.FileType, Flags);
                          at_Wma: GetWmaInfo(MainFile.WmaFile);
                          at_wav: GetWavInfo(MainFile.WavFile);
                      end;

                      // get general information from the file
                      // do this AFTER the specialized information because:
                      // the id3-stuff is a little bit more complicated here (charcode...)
                      // in the mp3-special-method the contained ID3-Settings are done.
                      // this should affect also the Getters in the TGeneralAudioFile
                      Artist := MainFile.Artist;
                      Titel  := MainFile.Title;
                      Album  := MainFile.Album;
                      Year   := MainFile.Year;
                      Track  := GetTrackFromV2TrackString(MainFile.Track);
                      Genre  := MainFile.Genre;
                      // Audio
                      fFileSize := MainFile.FileSize;
                      fDuration := MainFile.Duration;
                      fBitrate := MainFile.Bitrate Div 1000;
                      SetSampleRate(MainFile.Samplerate);

                      // Ignore Lyrics (far saving RAM on huge collections)
                      if (Flags AND GAD_NOLYRICS) = GAD_NOLYRICS then
                          Lyrics := '';

                  finally
                      MainFile.Free;
                  end;

                  if fFileSize = 0 then
                  begin
                      // this means: TGeneralAudioFile.Create(filename)
                      // could not determine the filetype from the file - so get at least its size
                      result := AUDIOERR_None;
                      if AudioFileExists(filename) then
                      begin
                          try
                              fs := TAudioFileStream.Create(filename, fmOpenRead or fmShareDenyWrite);
                              try
                                  fFileSize := fs.Size;
                              finally
                                  fs.Free;
                              end;
                          except
                              result := AUDIO_FILEERR_FOpenR;
                          end;
                      end else
                          result := AUDIO_FILEERR_NoFile;
                  end;
              end
          except
              result := AUDIOERR_Unkown;
              FileIsPresent := FileExists(filename);
              fFileSize := 0;
              SetUnknown;
          end;

      end; // at_File

      at_Stream: begin
            fFileSize := 0;
            fFileAge  := Now;
            result := AUDIOERR_None;
      end;

      at_CDDA: begin
          result := CDToAudioError(GetCDDAInfo(Filename, Flags));
      end
  else
      result := AUDIOERR_None;
  end;
end;

{
    --------------------------------------------------------
    GetMp3Info
    Uses MP3FileUtils
    --------------------------------------------------------
}
procedure TAudioFile.GetMp3Info(aMp3File: TMp3File; filename: UnicodeString; Flags: Integer = 0);
var  TagStream: TMemoryStream;
begin
    if NempCharCodeOptions.AutoDetectCodePage then
    begin
        aMp3File.ID3v1Tag.CharCode := GetCodePage(filename, NempCharCodeOptions);
        aMp3File.ID3v2Tag.CharCode := aMp3File.ID3v1Tag.CharCode;
    end;

    aMp3File.ID3v1Tag.AutoCorrectCodepage := NempCharCodeOptions.AutoDetectCodePage;
    aMp3File.ID3v2Tag.AutoCorrectCodepage := NempCharCodeOptions.AutoDetectCodePage;

    CD          := aMp3File.ID3v2Tag.GetText(IDv2_PARTOFASET);
    Lyrics      := UTF8Encode(aMp3File.id3v2tag.Lyrics);
    Comment     := aMp3File.Comment;
    PlayCounter := aMp3File.Id3v2tag.PlayCounter;
    // Determine rating if wanted.
    // Note: only if no rating is set!
    // Change January 2010: Set Rating if Flag is set OR (not AND as before) the current rating is zero
    // No: Read it always from ID3Tag, as ratings are always written into the tag on mp3-Files!
    // if ((Flags and GAD_Rating) = GAD_Rating) OR (fRating = 0) then
    fRating := aMp3File.id3v2tag.Rating;

    fvbr := aMp3File.MpegInfo.vbr;
    case aMp3File.MpegInfo.channelmode of
        // ('S ','JS','DC','M ','--');
        0: fChannelmodeIDX := 0; //Stereo
        1: fChannelmodeIDX := 1; //'Joint stereo',
        2: fChannelmodeIDX := 2; //'Dual channel (Stereo)',
        3: fChannelmodeIDX := 3; //'Single channel (Mono)');
        else fChannelmodeIDX := 4;
    end;

    // get Nemp/Tags
    TagStream := TMemoryStream.Create;
    try
        if aMp3File.id3v2tag.GetPrivateFrame('NEMP/Tags', TagStream) and (TagStream.Size > 0) then
        begin
            // We found a Tag-Frame with Information in the ID3Tag
            TagStream.Position := 0;
            SetLength(RawTagLastFM, TagStream.Size);
            TagStream.Read(RawTagLastFM[1], TagStream.Size);
        end else
            RawTagLastFM := '';
    finally
        TagStream.Free;
    end;

    // Get ReplayGain Information
    //fTrackGainStr :=  aMp3File.id3v2tag.GetUserText(REPLAYGAIN_TRACK_GAIN);
    //fAlbumGainStr :=  aMp3File.id3v2tag.GetUserText(REPLAYGAIN_ALBUM_GAIN);

    TrackGain := GainStringToSingle(aMp3File.id3v2tag.GetUserText(REPLAYGAIN_TRACK_GAIN));
    AlbumGain := GainStringToSingle(aMp3File.id3v2tag.GetUserText(REPLAYGAIN_ALBUM_GAIN));

    TrackPeak := PeakStringToSingle(aMp3File.id3v2tag.GetUserText(REPLAYGAIN_TRACK_PEAK));
    AlbumPeak := PeakStringToSingle(aMp3File.id3v2tag.GetUserText(REPLAYGAIN_ALBUM_PEAK));
end;

{
    --------------------------------------------------------
    GetFlacInfo
    --------------------------------------------------------
}
procedure TAudioFile.GetFlacInfo(aFlacFile: TFlacFile; Flags: Integer = 0);
begin
    CD      := aFlacFile.GetPropertyByFieldname(VORBIS_DISCNUMBER);
    Comment := aFlacFile.GetPropertyByFieldname(VORBIS_COMMENT);
    Lyrics  := UTF8String(aFlacFile.GetPropertyByFieldname(VORBIS_LYRICS));
    // Playcounter/Rating: Maybe incompatible with other Taggers
    PlayCounter := StrToIntDef(aFlacFile.GetPropertyByFieldname(VORBIS_PLAYCOUNT), 0);
    Rating :=  StrToIntDef(aFlacFile.GetPropertyByFieldname(VORBIS_RATING), 0);

    TrackGain := GainStringToSingle(aFlacFile.GetPropertyByFieldname(REPLAYGAIN_TRACK_GAIN));
    AlbumGain := GainStringToSingle(aFlacFile.GetPropertyByFieldname(REPLAYGAIN_ALBUM_GAIN));

    TrackPeak := PeakStringToSingle(aFlacFile.GetPropertyByFieldname(REPLAYGAIN_TRACK_PEAK));
    AlbumPeak := PeakStringToSingle(aFlacFile.GetPropertyByFieldname(REPLAYGAIN_ALBUM_PEAK));

    // LastFM-Tags/CATEGORIES: Probably Nemp-Only
    RawTagLastFM := UTF8String(aFlacFile.GetPropertyByFieldname(VORBIS_CATEGORIES));
    fVBR := False;
    case aFlacFile.Channels of
        1: fChannelModeIDX := 3; // Mono
        2: fChannelModeIDX := 0; // Stereo
        3..100: fChannelModeIDX := 5; // Multichannel
    else
        fChannelModeIDX := 4; // unknown
    end;
end;

{
    --------------------------------------------------------
    GetOggInfo
    New in Nemp 4.1: Use Selfmade-Unit "Flogger"
    --------------------------------------------------------
}
procedure TAudioFile.GetOggInfo(aOggFile: TOggVorbisFile; Flags: Integer = 0);
begin
    {
    if (Flags and GAD_Cover) = GAD_Cover then
        // clear ID, so MediaLibrary.GetCover can do its job
        CoverID := '';
    }
    fVBR := False;
    case aOggFile.Channels of
        1: fChannelModeIDX := 3; // Mono
        2: fChannelModeIDX := 0; // Stereo
        3..100: fChannelModeIDX := 5; // Multichannel
    else
        fChannelModeIDX := 4; // unknown
    end;
    // Additional Fields, not OGG-VORBIS-Standard but probably ok
    CD      := aOggFile.GetPropertyByFieldname(VORBIS_DISCNUMBER);
    Comment := aOggFile.GetPropertyByFieldname(VORBIS_COMMENT);
    Lyrics  := UTF8String(aOggFile.GetPropertyByFieldname(VORBIS_LYRICS));
    // Playcounter/Rating: Maybe incompatible with other Taggers
    PlayCounter := StrToIntDef(aOggFile.GetPropertyByFieldname(VORBIS_PLAYCOUNT), 0);
    Rating :=  StrToIntDef(aOggFile.GetPropertyByFieldname(VORBIS_RATING), 0);
    // LastFM-Tags/CATEGORIES: Probably Nemp-Only
    RawTagLastFM := UTF8String(aOggFile.GetPropertyByFieldname(VORBIS_CATEGORIES));

    TrackGain := GainStringToSingle(aOggFile.GetPropertyByFieldname(REPLAYGAIN_TRACK_GAIN));
    AlbumGain := GainStringToSingle(aOggFile.GetPropertyByFieldname(REPLAYGAIN_ALBUM_GAIN));

    TrackPeak := PeakStringToSingle(aOggFile.GetPropertyByFieldname(REPLAYGAIN_TRACK_PEAK));
    AlbumPeak := PeakStringToSingle(aOggFile.GetPropertyByFieldname(REPLAYGAIN_ALBUM_PEAK));
end;

{
    --------------------------------------------------------
    GetM4AInfo
    --------------------------------------------------------
}
procedure TAudioFile.GetM4AInfo(aM4AFile: TM4aFile; Flags: Integer);
begin

    CD      := aM4AFile.Disc;
    Comment := aM4AFile.Comment;
    Lyrics  := UTF8String(aM4AFile.Lyrics);
    // Playcounter/Rating: Maybe incompatible with other Taggers
    // PlayCounter := StrToIntDef(aFlacFile.GetPropertyByFieldname(VORBIS_PLAYCOUNT), 0);
    // Rating :=  StrToIntDef(aFlacFile.GetPropertyByFieldname(VORBIS_RATING), 0);
    // LastFM-Tags/CATEGORIES: Probably Nemp-Only
    RawTagLastFM := UTF8String(aM4AFile.Keywords);
    fVBR := False;
    case aM4AFile.Channels of
        1: fChannelModeIDX := 3; // Mono
        2: fChannelModeIDX := 0; // Stereo
        3..100: fChannelModeIDX := 5; // Multichannel
    else
        fChannelModeIDX := 4; // unknown
    end;

    PlayCounter := StrToIntDef(aM4AFile.GetSpecialData(DEFAULT_MEAN, M4APlayCounter),0);
    Rating      := StrToIntDef(aM4AFile.GetSpecialData(DEFAULT_MEAN, M4ARating), 0);

    TrackGain := GainStringToSingle(aM4AFile.GetSpecialData(DEFAULT_MEAN, REPLAYGAIN_TRACK_GAIN));
    AlbumGain := GainStringToSingle(aM4AFile.GetSpecialData(DEFAULT_MEAN, REPLAYGAIN_ALBUM_GAIN));

    TrackPeak := PeakStringToSingle(aM4AFile.GetSpecialData(DEFAULT_MEAN, REPLAYGAIN_TRACK_PEAK));
    AlbumPeak := PeakStringToSingle(aM4AFile.GetSpecialData(DEFAULT_MEAN, REPLAYGAIN_ALBUM_PEAK));
end;

{
    --------------------------------------------------------
    GetWmaInfo
    Uses ATL
    --------------------------------------------------------
}
procedure TAudioFile.GetWmaInfo(aWmaFile: TWmaFile);
begin
    // Zur�cksetzen, damit die Funktion MedienBib.InitCover sp�ter anschlagen kann!
    CoverID := '';
    //fRating := 0;  // Rating in WMA-Files is not supported
end;

{
    --------------------------------------------------------
    GetExoticInfo
    --------------------------------------------------------
}
procedure TAudioFile.GetExoticInfo(aBaseApeFile: TBaseApeFile; aType: TAudioFileType; Flags: Integer);
begin
    fVBR := False;
    // Get additonal Info from Apev2tags
    CD           := aBaseApeFile.GetValueByKey(APE_DISCNUMBER);
    Comment      := aBaseApeFile.GetValueByKey(APE_COMMENT);
    Lyrics       := UTF8String(aBaseApeFile.GetValueByKey(APE_LYRICS));
    PlayCounter  := StrToIntDef(aBaseApeFile.GetValueByKey(APE_PLAYCOUNT), 0);
    Rating       := StrToIntDef(aBaseApeFile.GetValueByKey(APE_RATING), 0);
    RawTagLastFM := UTF8String(aBaseApeFile.GetValueByKey(APE_CATEGORIES));
    TrackGain := GainStringToSingle(aBaseApeFile.GetValueByKey(REPLAYGAIN_TRACK_GAIN));
    AlbumGain := GainStringToSingle(aBaseApeFile.GetValueByKey(REPLAYGAIN_ALBUM_GAIN));
    TrackPeak := PeakStringToSingle(aBaseApeFile.GetValueByKey(REPLAYGAIN_TRACK_PEAK));
    AlbumPeak := PeakStringToSingle(aBaseApeFile.GetValueByKey(REPLAYGAIN_ALBUM_PEAK));
    // Get ChannelMode
    case aType of
        // MPP_MODE: array [0..2] of string = ('Unknown', 'Stereo', 'Joint Stereo');
        at_MusePack: begin
            case TMusePackFile(aBaseApeFile).ChannelModeID of
                1: fChannelModeIDX := 0; // Stereo
                2: fChannelModeIDX := 1; // Joint Stereo
            else
                fChannelModeIDX := 4; // unknown
            end;
        end;
        at_Monkey,
        at_WavPack,
        at_OptimFrog,
        at_TrueAudio: begin
            case aBaseApeFile.Channels of
                0: fChannelModeIDX := 4; // Stereo
                1: fChannelModeIDX := 3; // Mono
                2: fChannelModeIDX := 0; // invalid
            else
                fChannelModeIDX := 5; // MultiChannel
            end
        end;
    else
        // nothing to do
    end;
end;


{
    --------------------------------------------------------
    GetWavInfo
    Uses modified version of
    http://www.dsdt.info/tipps/?id=354&details=1
    --------------------------------------------------------
}
procedure TAudioFile.GetWavInfo(aWavFile: TWavFile);
begin
    // Zur�cksetzen, damit die Funktion MedienBib.InitCover sp�ter anschlagen kann!
    CoverID := '';
end;


function TAudioFile.GetCDDAInfo(Filename: UnicodeString;
  Flags: Integer): TCDDAError;
var cdFile: TCDDAFile;

begin

//result := cddaErr_None;
//exit;

    SetCDDADefaultInformation(self);
    cdFile := TCDDAFile.Create;
    try
        result := cdFile.GetData(Filename, (Flags and GAD_CDDB) = GAD_CDDB);

        if result = cddaErr_None then
        begin
            fTrack := cdFile.Track;
            Artist := cdFile.Artist;
            Titel := cdFile.Title;
            Album := cdFile.Album;
            fDuration := cdFile.Duration;
            Genre := cdFile.Genre;
            Year := cdFile.Year;
            Comment := cdFile.CddbID;
        end else
        begin
            fTrack := 0;
            Artist := '';
            Titel := 'Invalid Track';
            Album := '';
            fDuration := 0;
            Genre := '';
            Year := '';
            Comment := '';
            // Pfad := 'cdda:\\';     // do not do this!!!
        end;

    finally
        cdFile.Free;
    end;
end;


{
    --------------------------------------------------------
    GetCoverFromMetData  (new in 4.12)
    Get a Cover from the Metadata and store it into Parameter aCoverBmp
    result: Success yes/no
    --------------------------------------------------------
}

function TAudioFile.GetCoverStreamFromMetaData(aCoverStream: TMemoryStream; TagFile: TGeneralAudioFile): boolean;
// var MainFile: TGeneralAudioFile;
begin
    if not FileExists(Pfad) then
    begin
        result := False;
        exit;
    end;

    case fAudioType of
        at_File: begin
            try
                //MainFile := TGeneralAudioFile.Create(Pfad);
                //try
                    // get cover information (format-specific)
                    case TagFile.FileType of
                        at_Mp3    : result := GetCoverStreamFromMp3(TagFile.MP3File, aCoverStream) ;
                        at_Flac   : result := GetCoverStreamFromFlac(TagFile.FlacFile, aCoverStream) ;
                        at_M4A    : result := GetCoverStreamFromM4A(TagFile.M4aFile, aCoverStream) ;

                        at_Monkey,
                        at_WavPack,
                        at_MusePack,
                        at_OptimFrog,
                        at_TrueAudio: result := GetCoverStreamFromApe(TagFile.BaseApeFile, aCoverStream) ;

                        at_Invalid,
                        at_Ogg,
                        at_Wma,
                        at_wav: result := False;
                    else
                        result := False;
                    end;

                //finally
                //    MainFile.Free;
                //end;
            except
                result := False;
            end;

        end; // at_File
    else
        // not a File, but Stream, CDDA, ...
        result := False
    end;
end;


function TAudioFile.GetCoverFromMetaData(aCoverBmp: TBitmap): boolean;
var MainFile: TGeneralAudioFile;
begin
    if not FileExists(Pfad) then
    begin
        result := False;
        exit;
    end;

    case fAudioType of
        at_File: begin
            try
                MainFile := TGeneralAudioFile.Create(Pfad);
                try
                    // get cover information (format-specific)
                    case MainFile.FileType of
                        at_Mp3    : result := GetCoverFromMp3(MainFile.MP3File, aCoverBmp) ;
                        at_Flac   : result := GetCoverFromFlac(MainFile.FlacFile, aCoverBmp) ;
                        at_M4A    : result := GetCoverFromM4A(MainFile.M4aFile, aCoverBmp) ;

                        at_Monkey,
                        at_WavPack,
                        at_MusePack,
                        at_OptimFrog,
                        at_TrueAudio: result := GetCoverFromApe(MainFile.BaseApeFile, aCoverBmp) ;

                        at_Invalid,
                        at_Ogg,
                        at_Wma,
                        at_wav: result := False;
                    else
                        result := False;
                    end;

                finally
                    MainFile.Free;
                end;
            except
                result := False;
            end;

        end; // at_File
    else
        // not a File, but Stream, CDDA, ...
        result := False
    end;
end;

function TAudioFile.GetCoverStreamFromMp3 (aMp3File: TMp3File   ; var aPicStream: TMemoryStream): Boolean;
var PicList: TObjectlist;
    PicType: Byte;
    PicDesc: UnicodeString;
    PicMime: AnsiString;
    i: Integer;
begin
    result := False;
    PicList := aMp3File.id3v2Tag.GetAllPictureFrames;
    try
        if PicList.Count > 0 then
        begin
            // Check Pic-List.
            // Take the cover flagged as "frontcover" or the first one in the list.
            for i := PicList.Count - 1 downto 0 do
            begin
                aPicStream.Clear;
                TID3v2Frame(PicList[i]).GetPicture(PicMime, PicType, PicDesc, aPicStream);
                if PicType = 3 then //Front-Cover
                    break;
            end;
            result := True; // not aCoverBmp.Empty;
            // we found a cover, but it is not sure that there is valid picture data in it.
        end;
    finally
        PicList.Free;
    end;
end;


function TAudioFile.GetCoverFromMp3(aMp3File: TMp3File   ; aCoverBmp: TBitmap): Boolean;
var CoverStream: TMemoryStream;
    PicList: TObjectlist;
    PicType: Byte;
    PicDesc: UnicodeString;
    PicMime: AnsiString;
    i: Integer;
begin
    result := False;
    CoverStream := TMemoryStream.Create;
    PicList := aMp3File.id3v2Tag.GetAllPictureFrames;
    try
        if PicList.Count > 0 then
        begin
            // Check Pic-Liste.
            // Take the cover flagged as "frontcover" or the first one in the list.
            for i := PicList.Count - 1 downto 0 do
            begin
                CoverStream.Clear;
                TID3v2Frame(PicList[i]).GetPicture(PicMime, PicType, PicDesc, CoverStream);
                if PicType = 3 then //Front-Cover
                    break;
            end;
            PicStreamToBitmap(CoverStream, PicMime, aCoverBmp);
            result := not aCoverBmp.Empty;
        end;
    finally
        PicList.Free;
        CoverStream.Free;
    end;
end;

function TAudioFile.GetCoverStreamFromFlac(aFlacFile: TFlacFile ; var aPicStream: TMemoryStream): Boolean;
var PicType: Cardinal;
    Mime: AnsiString;
    Description: UnicodeString;
begin
    aPicStream.Clear;
    result := aFlacFile.GetPictureStream(aPicStream, PicType, Mime, Description);
end;

function TAudioFile.GetCoverFromFlac(aFlacFile: TFlacFile ; aCoverBmp: TBitmap): Boolean;
var CoverStream : TMemoryStream;
    PicType: Cardinal;
    Mime: AnsiString;
    Description: UnicodeString;
begin
    result := False;
    CoverStream := TMemoryStream.Create;
    try
        if aFlacFile.GetPictureStream(CoverStream, PicType, Mime, Description) then
        begin
            // Cover in FlacFile Found
            PicStreamToBitmap(CoverStream, Mime, aCoverBmp);
            result := not aCoverBmp.Empty;
        end;
    finally
        CoverStream.Free;
    end;
end;



function TAudioFile.GetCoverStreamFromM4A (aM4AFile: TM4aFile   ; var aPicStream: TMemoryStream): Boolean;
var picType: TM4APicTypes;
begin
    aPicStream.Clear;
    result := aM4AFile.GetPictureStream(aPicStream, picType)
end;

function TAudioFile.GetCoverFromM4A(aM4AFile: TM4aFile   ; aCoverBmp: TBitmap): Boolean;
var CoverStream: TMemoryStream;
    picType: TM4APicTypes;
    aMime: AnsiString;
begin
    result := False;
    CoverStream := TMemoryStream.Create;
    try
        if aM4AFile.GetPictureStream(CoverStream, picType) then
        begin
            case picType of
              M4A_JPG: aMime := 'image/jpeg';
              M4A_PNG: aMime := 'image/png';
              M4A_Invalid: aMime := '-'; // invalid
            end;
            // Cover in M4AFile Found
            PicStreamToBitmap(CoverStream, aMime, aCoverBmp);
            result := not aCoverBmp.Empty;
        end;
    finally
        CoverStream.Free;
    end;
end;


function TAudioFile.GetCoverStreamFromAPE (aBaseApeFile: TBaseApeFile; var aPicStream: TMemoryStream): Boolean;
var picList: TStringList;
    i: Integer;
    description: UnicodeString;
begin
    result := false;
    picList := TStringList.Create;
    try
        aBaseApeFile.GetAllPictureFrames(picList);
        if picList.Count > 0 then
        begin
            // get Front-Cover, or use first one in the List
            for i := PicList.Count - 1 downto 0 do
            begin
                aPicStream.Clear;
                aBaseApeFile.GetPicture(AnsiString(PicList[i]), aPicStream, description);
                if PicList[i] = String(TPictureTypeStrings[apt_Front]) then
                    break;
            end;
            result := True;
        end;
    finally
        picList.Free;
    end;
end;


function TAudioFile.GetCoverFromAPE(aBaseApeFile: TBaseApeFile; aCoverBmp: TBitmap): Boolean;
var picList: TStringList;
    i: Integer;
    description: UnicodeString;
    CoverStream: TMemoryStream;
begin
    result := false;
    picList := TStringList.Create;
    try
        aBaseApeFile.GetAllPictureFrames(picList);
        if picList.Count > 0 then
        begin
            CoverStream := TMemoryStream.Create;
            try
                // get Front-Cover, or use first one in the List
                for i := PicList.Count - 1 downto 0 do
                begin
                    CoverStream.Clear;
                    aBaseApeFile.GetPicture(AnsiString(PicList[i]), CoverStream, description);
                    if PicList[i] = String(TPictureTypeStrings[apt_Front]) then
                        break;
                end;

                if not PicStreamToBitmap(CoverStream, 'image/jpeg', aCoverBmp) then
                    if not PicStreamToBitmap(CoverStream, 'image/png', aCoverBmp) then
                        PicStreamToBitmap(CoverStream, 'image/bmp', aCoverBmp);
                result := not aCoverBmp.Empty;

            finally
                CoverStream.Free;
            end;
        end;
    finally
        picList.Free;
    end;
end;



{
    --------------------------------------------------------
    SetUnknown
    Default values, if no further information can be determined from the file
    --------------------------------------------------------
}
procedure TAudioFile.SetUnknown;
begin
  Titel := ''; //before Nemp 4.1: Dateiname;
  Artist := '';
  Album := '';
  Year := '';
  Genre := '';
  Duration := 0;
  fBitrate := 0;
  fvbr := False;
  fChannelmodeIDX := 4;
  fSamplerateIDX := 9;
  Track := 0;
  CD := '';
  fRating := 0;
  // Zur�cksetzen, damit die Funktion MedienBib.InitCover sp�ter anschlagen kann!
  CoverID := '';
end;


{
    --------------------------------------------------------
    HasSupportedTagFormat
    --------------------------------------------------------
}
function TAudioFile.HasSupportedTagFormat: Boolean;
var ext: String;
begin
    ext := AnsiLowercase(Extension);

    result := (fAudioType = at_File)
          and (
               (ext = 'mp3')
            or (ext = 'ogg')
            or (ext = 'flac')
            or (ext = 'm4a')
            or (ext = 'mp4')
            or (ext = 'ape')
            or (ext = 'mpc')
            // other extensions or really rare used formats
            or (ext = 'mp2')
            or (ext = 'mp1')
            or (ext = 'oga')
            or (ext = 'fla')
            or (ext = 'mac')
            or (ext = 'wv')
            or (ext = 'mp+')
            or (ext = 'mpp')
            or (ext = 'ofr')
            or (ext = 'ofs')
            or (ext = 'tta')
          );
end;

function TAudioFile.ChangeTag(oldTag, newTag: String): Boolean;
var idx, idx1: Integer;
    sl: TStringList;
begin
    if RawTagLastFM = '' then
        // nothing to do
        result := false
    else
    begin
        sl := TStringList.Create;
        try
            sl.Text := String(RawTagLastFM);
            sl.CaseSensitive := False;


            idx := sl.IndexOf(oldTag);
            if idx >= 0 then
            begin
                result := True;
                ID3TagNeedsUpdate := True;

                if newTag = '' then
                    sl.Delete(idx)
                else
                begin
                    idx1 := sl.IndexOf(newTag);
                    if idx1 >= 0 then
                        // newTag already exists
                        sl.Delete(idx)
                    else
                        sl[idx] := newTag;
                end;
                // Set RawTag again
                if sl.Count > 0 then
                    RawTagLastFM := UTf8String(trim(sl.Text))
                else
                    RawTagLastFM := ''; // just to be sure, empty Stringlist may return "#13#10"?
            end else
                result := false;

        finally
            sl.Free
        end;
    end;
end;

function TAudioFile.ContainsTag(aTag: String): Boolean;
var sl: TStringList;
begin
    if RawTagLastFM = '' then
        // nothing to do
        result := false
    else
    begin
        sl := TStringList.Create;
        try
            sl.Text := String(RawTagLastFM);
            sl.CaseSensitive := False;
            result := sl.IndexOf(aTag) >= 0;
        finally
            sl.Free
        end;
    end;
end;

function TAudioFile.RemoveTag(aTag: String): Boolean;
var currentTagList: TStringlist;
    idx: Integer;
begin
    currentTagList := TStringlist.Create;
    try
        currentTagList.Text := String(RawTagLastFM);
        currentTagList.CaseSensitive := False;

        // get the index of oldTag and delete it
        idx := currentTagList.IndexOf(aTag);
        if idx > -1 then
        begin
            currentTaglist.Delete(idx);
            // set RawTags again
            RawTagLastFM := UTF8String(Trim(currentTaglist.Text));
            result := True;
        end else
            result := False;
    finally
        currenttagList.Free;
    end;
end;


{
    --------------------------------------------------------
    SetAudioData
    Write all Data to the Tag of an AudioFile
    Used, in MainVST.
    --------------------------------------------------------
}
function TAudioFile.PreparingWriteChecks(allowChange: Boolean): TNempAudioError;
begin
    if Not AllowChange then
        result := AUDIOERR_EditingDenied
    else
        if Not IsFile then
            result := AUDIOERR_UnsupportedMediaFile
        else
            result := AUDIOERR_None;
end;
procedure TAudioFile.EnsureID3v2Exists(aMp3File: TMp3File);
begin
    if not aMp3File.ID3v2Tag.Exists then
    begin
        // we DO need the ID3v2-Tag now, so write *both*
        // (we have to assume that there is already some metadata, so ID3v1 should exist anyway ...)
        aMp3File.TagWriteMode := id3_Both;
        // aMp3File.ID3v2Tag.Exists := True; // so that it is written into the file later
        // copy basic information to ID3v2Tag
        aMp3File.ID3v2Tag.Artist  := self.Artist  ;
        aMp3File.ID3v2Tag.Title   := self.Titel   ;
        aMp3File.ID3v2Tag.Album   := self.Album   ;
        aMp3File.ID3v2Tag.Genre   := self.Genre   ;
        aMp3File.ID3v2Tag.Comment := self.Comment ;
        if (self.Year <> '') and (self.Year <> '0') then
            aMp3File.ID3v2Tag.Year := self.Year;
        if self.Track <> 0 then
            aMp3File.ID3v2Tag.Track := IntToStr(self.Track);
    end;
end;
function TAudioFile.WriteStringToMetaData(aValue: String; ColumnIndex: Integer; allowChange: Boolean): TNempAudioError;
var MainFile: TGeneralAudioFile;
begin
    result := PreparingWriteChecks(allowChange);
    if result = AUDIOERR_None then
    begin
        MainFile := TGeneralAudioFile.Create(pfad);
        try
            if MainFile.LastError = FileErr_NotSupportedFileType then
                result := AUDIOERR_UnsupportedMediaFile
            else
            begin
                case ColumnIndex of

                    CON_ARTIST : MainFile.Artist := aValue;
                    CON_TITEL  : MainFile.Title  := aValue ;
                    CON_ALBUM  : MainFile.Album  := aValue ;
                    CON_YEAR   : MainFile.Year := aValue;
                    CON_GENRE  : begin
                        // for non-standard genres, we need the ID3v2Tag
                        if MainFile.FileType = at_Mp3 then
                        begin
                              if NOT (ID3Genres.IndexOf(aValue) in [0..125]) then
                                  EnsureID3v2Exists(MainFile.Mp3File);
                        end;
                        MainFile.Genre := aValue;
                    end;

                    CON_TRACKNR: begin
                          MainFile.Track := aValue;  //StrToIntDef(aValue, 0);
                    end;
                    CON_STANDARDCOMMENT: begin
                        case MainFile.FileType of
                            at_Mp3: MainFile.Mp3File.Comment := aValue;
                            at_Ogg: MainFile.OggFile.SetPropertyByFieldname(VORBIS_COMMENT, aValue);
                            at_Flac: MainFile.FlacFile.SetPropertyByFieldname(VORBIS_COMMENT, aValue);
                            at_M4A: MainFile.M4aFile.Comment := aValue;
                            at_Monkey,
                            at_WavPack,
                            at_MusePack,
                            at_OptimFrog,
                            at_TrueAudio: MainFile.BaseApeFile.SetValueByKey(APE_COMMENT, aValue);
                            //  at_Invalid: ; at_Wma: ; at_Wav: ;
                        end;
                    end;

                    CON_CD: begin
                        case MainFile.FileType of
                            at_Mp3: begin
                                EnsureID3v2Exists(MainFile.Mp3File);
                                MainFile.Mp3File.ID3v2Tag.SetText(IDv2_PARTOFASET, aValue);
                            end;
                            at_Ogg: MainFile.OggFile.SetPropertyByFieldname(VORBIS_DISCNUMBER, aValue);
                            at_Flac: MainFile.FlacFile.SetPropertyByFieldname(VORBIS_DISCNUMBER, aValue);
                            at_M4A: MainFile.M4aFile.Disc := aValue;
                            at_Monkey,
                            at_WavPack,
                            at_MusePack,
                            at_OptimFrog,
                            at_TrueAudio: MainFile.BaseApeFile.SetValueByKey(APE_DISCNUMBER, aValue);
                            //  at_Invalid: ; at_Wma: ; at_Wav: ;
                        end;
                    end;
                end;

                result := AudioToNempAudioError(MainFile.UpdateFile);
            end;
        finally
            MainFile.Free;
        end;
    end;
end;
function TAudioFile.WriteLyricsToMetaData(aValue: UTF8String; allowChange: Boolean): TNempAudioError;
var MainFile: TGeneralAudioFile;
begin
    result := PreparingWriteChecks(allowChange);
    if result = AUDIOERR_None then
    begin
        MainFile := TGeneralAudioFile.Create(pfad);
        try
            if MainFile.LastError = FileErr_NotSupportedFileType then
                result := AUDIOERR_UnsupportedMediaFile
            else
            begin
                // bei mp3-Dateien war hier noch ne Abfrage "if Lyrics <> '' " dabei .... warum? Checken?
                        case MainFile.FileType of
                            at_Mp3: begin
                                EnsureID3v2Exists(MainFile.Mp3File);
                                MainFile.Mp3File.ID3v2Tag.Lyrics := String(aValue);
                            end;
                            at_Ogg: MainFile.OggFile.SetPropertyByFieldname(VORBIS_LYRICS, String(aValue));
                            at_Flac: MainFile.FlacFile.SetPropertyByFieldname(VORBIS_LYRICS, String(aValue));
                            at_M4A: MainFile.M4aFile.Lyrics := String(aValue);
                            at_Monkey,
                            at_WavPack,
                            at_MusePack,
                            at_OptimFrog,
                            at_TrueAudio: MainFile.BaseApeFile.SetValueByKey(APE_LYRICS, String(aValue));
                            //  at_Invalid: ; at_Wma: ; at_Wav: ;
                        end;
                result := AudioToNempAudioError(MainFile.UpdateFile);
            end;
        finally
            MainFile.Free;
        end;
    end;
end;
function TAudioFile.WriteRawTagsToMetaData(aValue: UTF8String; allowChange: Boolean): TNempAudioError;
var MainFile: TGeneralAudioFile;
    ms: TMemoryStream;
begin
    result := PreparingWriteChecks(allowChange);
    if result = AUDIOERR_None then
    begin
        MainFile := TGeneralAudioFile.Create(pfad);
        try
            if MainFile.LastError = FileErr_NotSupportedFileType then
                result := AUDIOERR_UnsupportedMediaFile
            else
            begin
                        case MainFile.FileType of
                            at_Mp3: begin
                                  if length(aValue) > 0 then
                                  begin
                                      EnsureID3v2Exists(MainFile.Mp3File);
                                      ms := TMemoryStream.Create;
                                      try
                                          ms.Write(aValue[1], length(aValue));
                                          MainFile.Mp3File.ID3v2Tag.SetPrivateFrame('NEMP/Tags', ms);
                                      finally
                                          ms.Free;
                                      end;
                                  end else
                                      // delete Tags-Frame
                                      MainFile.Mp3File.ID3v2Tag.SetPrivateFrame('NEMP/Tags', NIL);
                            end;
                            at_Ogg: MainFile.OggFile.SetPropertyByFieldname(VORBIS_CATEGORIES, String(aValue));
                            at_Flac: MainFile.FlacFile.SetPropertyByFieldname(VORBIS_CATEGORIES, String(aValue));
                            at_M4A: MainFile.M4aFile.Keywords := String(aValue);
                            at_Monkey,
                            at_WavPack,
                            at_MusePack,
                            at_OptimFrog,
                            at_TrueAudio: MainFile.BaseApeFile.SetValueByKey(APE_CATEGORIES , String(aValue));
                            //  at_Invalid: ; at_Wma: ; at_Wav: ;
                        end;

                result := AudioToNempAudioError(MainFile.UpdateFile);
            end;
        finally
            MainFile.Free;
        end;
    end;
end;
function TAudioFile.WriteRatingsToMetaData(aRating: Integer; allowChange: Boolean): TNempAudioError;
var MainFile: TGeneralAudioFile;
    StrRating: String;
begin
    result := PreparingWriteChecks(allowChange);
    if result = AUDIOERR_None then
    begin
        MainFile := TGeneralAudioFile.Create(pfad);
        try
            if MainFile.LastError = FileErr_NotSupportedFileType then
                result := AUDIOERR_UnsupportedMediaFile
            else
            begin
                if aRating > 0 then
                    StrRating  := IntToStr(aRating)
                else
                    StrRating := '';

                case MainFile.FileType of
                  at_Mp3:  begin
                      EnsureID3v2Exists(MainFile.Mp3File);
                      MainFile.Mp3File.ID3v2Tag.SetRatingAndCounter('*', aRating, -1);
                  end;
                  at_Ogg:  MainFile.OggFile.SetPropertyByFieldname(VORBIS_RATING  , StrRating );
                  at_Flac: MainFile.FlacFile.SetPropertyByFieldname(VORBIS_RATING , StrRating );
                  at_M4A:  MainFile.M4AFile.SetSpecialData(DEFAULT_MEAN, M4ARating, StrRating );
                  at_Monkey,
                  at_WavPack,
                  at_MusePack,
                  at_OptimFrog,
                  at_TrueAudio: MainFile.BaseApeFile.SetValueByKey(APE_RATING, StrRating );
                  //at_Wma: ; at_Invalid: ; at_Wav: ;
                end;

                result := AudioToNempAudioError(MainFile.UpdateFile);
            end;
        finally
            MainFile.Free;
        end;
    end;
end;

function TAudioFile.WritePlayCounterToMetaData(aPlayCounter: Integer; allowChange: Boolean): TNempAudioError;
var MainFile: TGeneralAudioFile;
    StrCounter: String;

begin
    result := PreparingWriteChecks(allowChange);
    if result = AUDIOERR_None then
    begin
        MainFile := TGeneralAudioFile.Create(pfad);
        try
            if MainFile.LastError = FileErr_NotSupportedFileType then
                result := AUDIOERR_UnsupportedMediaFile
            else
            begin
                      if aPlayCounter > 0 then StrCounter := IntToStr(aPlayCounter) else StrCounter := '';

                      case MainFile.FileType of
                        at_Mp3 : begin
                            EnsureID3v2Exists(MainFile.Mp3File);
                            MainFile.Mp3File.ID3v2Tag.SetRatingAndCounter('*', -1, aPlayCounter);
                        end;
                        at_Ogg : MainFile.OggFile.SetPropertyByFieldname(VORBIS_PLAYCOUNT, StrCounter);
                        at_Flac: MainFile.FlacFile.SetPropertyByFieldname(VORBIS_PLAYCOUNT, StrCounter);
                        at_M4A : MainFile.M4AFile.SetSpecialData(DEFAULT_MEAN, M4APlayCounter, StrCounter);
                        at_Monkey,
                        at_WavPack,
                        at_MusePack,
                        at_OptimFrog,
                        at_TrueAudio:  MainFile.BaseApeFile.SetValueByKey(APE_PLAYCOUNT  , StrCounter);
                        //at_Wma: ; at_Invalid: ; at_Wav: ;
                      end;

                result := AudioToNempAudioError(MainFile.UpdateFile);
            end;
        finally
            MainFile.Free;
        end;
    end;
end;


function TAudioFile.WriteReplayGainToMetaData(aTrackGain, aAlbumGain, aTrackPeak, aAlbumPeak: Single; Flags: Integer; allowChange: Boolean): TNempAudioError;
var MainFile: TGeneralAudioFile;
    strAlbum, strTrack, strTrackPeak, strAlbumPeak: String;
    doUpdateTrack, doUpdateAlbum: Boolean;
const INVALID_STR = '----';
begin
    result := PreparingWriteChecks(allowChange);
    if result = AUDIOERR_None then
    begin
        MainFile := TGeneralAudioFile.Create(pfad);
        try
            if MainFile.LastError = FileErr_NotSupportedFileType then
                result := AUDIOERR_UnsupportedMediaFile
            else
            begin
                  {
                      RG_SetTrack = 1;
                      RG_SetAlbum = 2;
                      RG_SetBoth  = 3; // = RG_SetTrack OR RG_SetAlbum
                      RG_ClearTrack = 4;
                      RG_ClearAlbum = 8;
                      RG_ClearBoth = 12; // = RG_ClearTrack OR RG_ClearAlbum
                  }
                      // Init Strings with invalid Data
                      strTrack := INVALID_STR;
                      strAlbum := INVALID_STR;
                      strTrackPeak := INVALID_STR;
                      strAlbumPeak := INVALID_STR;
                      // 1.) Convert Values into Strings, according to the Flags
                      if (Flags AND RG_ClearTrack) = RG_ClearTrack then strTrack := '';
                      if (Flags AND RG_ClearTrack) = RG_ClearTrack then strTrackPeak := '';
                      if (Flags AND RG_SetTrack)   = RG_SetTrack   then strTrack := GainValueToString(aTrackGain);
                      if (Flags AND RG_SetTrack)   = RG_SetTrack   then strTrackPeak := PeakValueToString(aTrackPeak);

                      if (Flags AND RG_ClearAlbum) = RG_ClearAlbum then strAlbum := '';
                      if (Flags AND RG_ClearAlbum) = RG_ClearAlbum then strAlbumPeak := '';
                      if (Flags AND RG_SetAlbum)   = RG_SetAlbum   then strAlbum := GainValueToString(aAlbumGain);
                      if (Flags AND RG_SetAlbum)   = RG_SetAlbum   then strAlbumPeak := PeakValueToString(aAlbumPeak);

                      // if we want to set or clear a value: actually do update the metadata
                      doUpdateTrack := strTrack <> INVALID_STR;
                      doUpdateAlbum := strAlbum <> INVALID_STR;
                      case MainFile.FileType of
                          at_Mp3: begin
                                EnsureID3v2Exists(MainFile.Mp3File);
                                if doUpdateTrack then
                                begin
                                    MainFile.Mp3File.ID3v2Tag.SetUserText(REPLAYGAIN_TRACK_GAIN, strTrack);
                                    MainFile.Mp3File.ID3v2Tag.SetUserText(REPLAYGAIN_TRACK_PEAK, strTrackPeak);
                                end;
                                if doUpdateAlbum then
                                begin
                                    MainFile.Mp3File.ID3v2Tag.SetUserText(REPLAYGAIN_ALBUM_GAIN, strAlbum);
                                    MainFile.Mp3File.ID3v2Tag.SetUserText(REPLAYGAIN_ALBUM_PEAK, strAlbumPeak);
                                end;
                          end;
                          at_Ogg: begin
                                if doUpdateTrack then begin
                                    MainFile.OggFile.SetPropertyByFieldname(REPLAYGAIN_TRACK_GAIN, strTrack  );
                                    MainFile.OggFile.SetPropertyByFieldname(REPLAYGAIN_TRACK_PEAK, strTrackPeak  );
                                end;
                                if doUpdateAlbum then
                                begin
                                    MainFile.OggFile.SetPropertyByFieldname(REPLAYGAIN_ALBUM_GAIN, strAlbum  );
                                    MainFile.OggFile.SetPropertyByFieldname(REPLAYGAIN_ALBUM_PEAK, strAlbumPeak  );
                                end;
                          end;

                          at_Flac: begin
                                if doUpdateTrack then begin
                                    MainFile.FlacFile.SetPropertyByFieldname(REPLAYGAIN_TRACK_GAIN, strTrack  );
                                    MainFile.FlacFile.SetPropertyByFieldname(REPLAYGAIN_TRACK_PEAK, strTrackPeak  );
                                end;
                                if doUpdateAlbum then begin
                                    MainFile.FlacFile.SetPropertyByFieldname(REPLAYGAIN_ALBUM_GAIN, strAlbum  );
                                    MainFile.FlacFile.SetPropertyByFieldname(REPLAYGAIN_ALBUM_PEAK, strAlbumPeak  );
                                end;
                          end;
                          at_M4A: begin
                                if doUpdateTrack then begin
                                    MainFile.M4AFile.SetSpecialData(DEFAULT_MEAN, REPLAYGAIN_TRACK_GAIN, strTrack );
                                    MainFile.M4AFile.SetSpecialData(DEFAULT_MEAN, REPLAYGAIN_TRACK_PEAK, strTrackPeak );
                                end;
                                if doUpdateAlbum then begin
                                    MainFile.M4AFile.SetSpecialData(DEFAULT_MEAN, REPLAYGAIN_ALBUM_GAIN, strAlbum );
                                    MainFile.M4AFile.SetSpecialData(DEFAULT_MEAN, REPLAYGAIN_ALBUM_PEAK, strAlbumPeak );
                                end;
                          end;
                          at_Monkey,
                          at_WavPack,
                          at_MusePack,
                          at_OptimFrog,
                          at_TrueAudio: begin
                                if doUpdateTrack then begin
                                    MainFile.BaseApeFile.SetValueByKey(REPLAYGAIN_TRACK_GAIN, strTrack);
                                    MainFile.BaseApeFile.SetValueByKey(REPLAYGAIN_TRACK_PEAK, strTrackPeak);
                                end;
                                if doUpdateAlbum then begin
                                    MainFile.BaseApeFile.SetValueByKey(REPLAYGAIN_ALBUM_GAIN, strAlbum);
                                    MainFile.BaseApeFile.SetValueByKey(REPLAYGAIN_ALBUM_PEAK, strAlbumPeak);
                                end;
                          end;
                          // at_Invalid: ;at_Wma: ; at_Wav: ;

                          {
                          at_Ogg : MainFile.OggFile.SetPropertyByFieldname(VORBIS_PLAYCOUNT, StrCounter);
                        at_Flac: MainFile.FlacFile.SetPropertyByFieldname(VORBIS_PLAYCOUNT, StrCounter);
                        at_M4A : MainFile.M4AFile.SetSpecialData(DEFAULT_MEAN, M4APlayCounter, StrCounter);
                        ...
                        ...
                        MainFile.BaseApeFile.SetValueByKey(APE_PLAYCOUNT  , StrCounter);

                          }

                      end;

                result := AudioToNempAudioError(MainFile.UpdateFile);
            end;
        finally
            MainFile.Free;
        end;
    end;
end;

function TAudioFile.WriteUserCoverIDToMetaData(aValue: AnsiString; allowChange: Boolean): TNempAudioError;
var MainFile: TGeneralAudioFile;
    ms: TMemoryStream;

begin
    result := PreparingWriteChecks(allowChange);
    if result = AUDIOERR_None then
    begin
        MainFile := TGeneralAudioFile.Create(pfad);
        try
            if MainFile.LastError = FileErr_NotSupportedFileType then
                result := AUDIOERR_UnsupportedMediaFile
            else
            begin
                case MainFile.FileType of
                    at_Mp3: begin
                          if length(aValue) > 0 then
                          begin
                              EnsureID3v2Exists(MainFile.Mp3File);
                              ms := TMemoryStream.Create;
                              try
                                  ms.Write(aValue[1], length(aValue));
                                  MainFile.Mp3File.ID3v2Tag.SetPrivateFrame('NEMP/UserCoverID', ms);
                              finally
                                  ms.Free;
                              end;
                          end else
                              // delete UserCoverID-Frame
                              MainFile.Mp3File.ID3v2Tag.SetPrivateFrame('NEMP/UserCoverID', NIL);
                    end;

                    at_Ogg : MainFile.OggFile.SetPropertyByFieldname(VORBIS_USERCOVERID, String(aValue));
                    at_Flac: MainFile.FlacFile.SetPropertyByFieldname(VORBIS_USERCOVERID, String(aValue));
                    at_M4A : MainFile.M4AFile.SetSpecialData(DEFAULT_MEAN, M4AUserCoverID, String(aValue));
                    at_Monkey,
                    at_WavPack,
                    at_MusePack,
                    at_OptimFrog,
                    at_TrueAudio:  MainFile.BaseApeFile.SetValueByKey(APE_USERCOVERID  , String(aValue));
                    //at_Wma: ; at_Invalid: ; at_Wav: ;
                end;

                result := AudioToNempAudioError(MainFile.UpdateFile);
            end;
        finally
            MainFile.Free;
        end;
    end;
end;

function TAudioFile.GetUserCoverIDFromMetaData(TagFile: TGeneralAudioFile): String;
var ms: TMemoryStream;
    AnsiID: AnsiString;
begin
    if fAudioType <> at_File then
        result := ''
    else
    begin
          case TagFile.FileType of
              at_Mp3:  begin
                          ms := TMemoryStream.Create;
                          try
                              TagFile.Mp3File.ID3v2Tag.GetPrivateFrame('NEMP/UserCoverID', ms);
                              ms.Position := 0;
                              SetLength(AnsiID, ms.Size);
                              ms.Read(AnsiID[1], ms.Size);
                              result := String(AnsiID);
                          finally
                              ms.Free;
                          end;
              end;
              at_Ogg : result := TagFile.OggFile.GetPropertyByFieldname(VORBIS_USERCOVERID);
              at_Flac: result := TagFile.FlacFile.GetPropertyByFieldname(VORBIS_USERCOVERID);
              at_M4A : result := TagFile.M4AFile.GetSpecialData(DEFAULT_MEAN, M4AUserCoverID);

              at_Monkey,
              at_WavPack,
              at_MusePack,
              at_OptimFrog,
              at_TrueAudio:  result := TagFile.BaseApeFile.GetValueByKey(APE_USERCOVERID);

              at_Invalid,
              at_Wma,
              at_Wav: result := '';
          end;
    end;
end;


{
    --------------------------------------------------------
    2 Helpers for CueSheets
    --------------------------------------------------------
}
function GetCueID(aString: String): Byte;
begin
  aString := trim(aString);
  if AnsiStartsText('PERFORMER', aString) then
    result := CUE_ID_PERFORMER
  else
    if AnsiStartsText('TITLE', aString) then
      result := CUE_ID_TITLE
    else
      if AnsiStartsText('FILE', aString) then
        result := CUE_ID_FILE
      else
        if AnsiStartsText('TRACK', aString) then
          result := CUE_ID_TRACK
        else
          if AnsiStartsText('INDEX', aString) then
            result := CUE_ID_INDEX
          else
            result := CUE_ID_UNKNOWN;
end;
function GetFileNameFromCueString(aString: String):String;
var i, LastSpacePos: Integer;
begin
  aString := trim(aString);
  LastSpacePos := 1;

  for i := length(aString) downto 1 do
    if aString[i] = ' ' then
    begin
      LastSpacePos := i;
      break;
    end;
  result := copy(aString, 6, LastSpacePos - 6);

  result := Stringreplace(result, '"', '', [rfReplaceAll]);
end;

{
    --------------------------------------------------------
    GetCueList
    Parse a CueSheet and add the found Cues to the Cuelist
    of the AudioFile
    --------------------------------------------------------
}
function TAudioFile.GetCueList(aCueFilename: UnicodeString =''; aAudioFilename: UnicodeString = ''): boolean;
var tmplist, CueTimelist, CueParselist: TStringList;
    i: Integer;
    FileFound: boolean;
    aCue: TAudioFile;

    function TrimGF(s: String): String;
    var l: Integer;
    begin
        l := length(s);
        if (l > 0) and (s[1] = '"') and (s[l] = '"') then
            result := s.Substring(1, l-2)
        else
            result := s;
    end;

begin
  // Defaultvalue for aAudioFilename: Filename of "self"
  if (aAudioFilename = '') then aAudioFilename := Dateiname else
    aAudioFileName := ExtractFileName(aAudioFilename);

  // Defaultvalue for aAudioFilename: Filename of "self" with extension .cue
  if (aCueFilename = '') then aCueFilename := ChangeFileExt(Self.Pfad, '.cue');

  if not FileExists(aCueFilename) then
  begin
    result := False;
    exit;
    // no cuesheet found
  end;

  tmplist := TStringList.Create;
  tmplist.LoadFromFile(aCueFilename);

  // FileFound:
  // Search for a FILE - entry with matching filename in the cuesheet-file
  // below this line in the sheet the "interesting data" will be found
  FileFound := False;

  // Create CueList or Clear existing
  if not assigned(Cuelist) then
    CueList := TObjectlist.Create(True)
  else
    CueList.Clear;

  aCue := Nil;
  for i:=0 to tmplist.Count - 1 do
  begin
    if Not FileFound then
    begin
          // search for FILE
          if (GetCueID(tmplist[i]) = CUE_ID_FILE) then
          begin
            // FILE found - Check filename
            if AnsiSameText (GetFileNameFromCueString(tmplist[i]) , aAudioFilename) then
               FileFound := True;
          end;
    end else
    begin
      // A FILE was found. Determine cue-information
      case GetCueID(tmplist[i]) of
        CUE_ID_TRACK: begin
                        aCue := TAudioFile.Create;
                        aCue.AudioType := at_CUE;
                        aCue.Pfad := Pfad;
                        CueList.Add(aCue);
                      end;
        CUE_ID_TITLE: begin
                        if assigned(aCue) then
                          aCue.Titel := TrimGF(copy(trim(tmplist[i]), 7, length(tmplist[i])));
                      end;
        CUE_ID_PERFORMER: begin
                        if assigned(aCue) then
                          aCue.Artist := TrimGF(copy(trim(tmplist[i]), 11, length(tmplist[i])));
                      end;
        CUE_ID_INDEX: begin
                        if assigned(aCue) then
                        begin
                            CueParselist := Explode(' ', trim(tmplist[i]));
                            if CueParselist.Count > 0 then
                            begin
                                CueTimelist := explode(':', CueParselist[CueParselist.Count - 1]);
                                try
                                    if CueTimeList.Count > 0 then
                                      aCue.FIndex01 := 60 * StrToInt(CueTimelist[0]);
                                    if CueTimeList.Count > 1 then
                                      aCue.FIndex01 := aCue.FIndex01 + StrToInt(CueTimelist[1]);
                                    if CueTimeList.Count > 2 then
                                      aCue.FIndex01 := aCue.FIndex01 + (StrToInt(CueTimelist[2]) / 75);
                                except
                                    CueList.Extract(aCue);
                                    FreeAndNil(aCue);
                                end;
                                CueTimelist.free;
                            end;
                            CueParselist.Free;
                        end;
                      end;
        CUE_ID_FILE: break;
                     // Next FILE found. Break.
      end;
    end;
  end;
  tmplist.Free;
  result := True;
end;

{
    --------------------------------------------------------
    GenerateCSVString
    --------------------------------------------------------
}
function TAudioFile.GenerateCSVString: UnicodeString;
var vbrstr, Lyricsstr : UnicodeString;
begin
  if fvbr then
    vbrstr := 'vbr'
  else
    vbrstr := 'cbr';

  if LyricsExisting then
    Lyricsstr := 'ok'
  else
    Lyricsstr := 'N/A';

  result :=
    StringReplace(Artist, ';', ',', [rfReplaceAll]) + ';' +
    StringReplace(Titel, ';', ',', [rfReplaceAll]) + ';' +
    StringReplace(Album, ';', ',', [rfReplaceAll]) + ';' +
    StringReplace(Genre, ';', ',', [rfReplaceAll]) + ';' +
    StringReplace(Year, ';', ',', [rfReplaceAll]) + ';' +
    IntToStr(Track) + ';' +
    StringReplace(Dateiname, ';', ',', [rfReplaceAll]) + ';' +
    StringReplace(Ordner, ';', ',', [rfReplaceAll]) + ';' +
    IntToStr(fFileSize) + ';' +
    IntToStr(Duration) + ';' +
    IntToStr(fBitrate) + ';' +
    ChannelMode + ';' +
    SamplerateShort + ';' +
    IntToStr(Rating) + ';' +
    IntToStr(PlayCounter) + ';' +
    vbrstr + ';' +
    Lyricsstr  ;
end;

{
    --------------------------------------------------------
    ReadTextFromStream
    Note: Probably only the case-2-code is used, as I use
          only utf-8-encoding for saving Audiofiles since
          Nemp Version-I-Dont-Know
    --------------------------------------------------------
}

function TAudioFile.ReadTextFromStream_DEPRECATED(aStream: TStream): UnicodeString;
var tmpStr: String;
    TextEncoding: Byte;
    len: integer;
    tmputf8: UTF8String;
begin
  aStream.Read(TextEncoding, SizeOf(TextEncoding));
  case TextEncoding of
      0:  begin
            // Ansi
            aStream.Read(len,sizeof(len));
            setlength(tmpStr, len);
            aStream.Read(Pchar(tmpStr)^,len);
            result := tmpstr;
          end;
      1: begin
            // Unicode
            aStream.Read(len,sizeof(len));
            Setlength(result, len Div 2);
            aStream.Read(PWidechar(result)^,len);
          end
      else begin // UTF8
            aStream.Read(len,sizeof(len));
            setlength(tmputf8, len);
            aStream.Read(PAnsiChar(tmputf8)^, len);
            result := UTF8ToString(tmputf8);
         end;
  end;
end;


{
    --------------------------------------------------------
    LoadFromStream
    Load AudioFile-structure from stream
    --------------------------------------------------------
}

procedure TAudioFile.LoadDataFromStream(aStream: TStream; JustForPlaylist: Boolean);
var c: Integer;
    DataID: Byte;
    GenreIDX:byte;
    Wyear: word;
    tmpStr: UnicodeString;
begin
    c := 0;
    repeat
        aStream.Read(DataID, sizeof(DataID));
        inc(c);
        case DataID of
            MP3DB_PFAD:  begin
                              if JustForPlaylist then
                              begin
                                  // file is for the playlist. Use relative paths here
                                  tmpStr := ReadTextFromStream(aStream);
                                  Pfad := tmpStr;  // this will set fAudioType!
                                  if fAudioType = at_File then
                                      Pfad := ExpandFilename(tmpStr)
                                  else
                                      FileIsPresent := True;
                              end
                              else
                                  // File is for the library
                                  pfad   := ReadTextFromStream(aStream);
                         end;
            MP3DB_ARTIST:  Artist     := ReadTextFromStream(aStream);
            MP3DB_TITEL:   Titel      := ReadTextFromStream(aStream);
            MP3DB_ALBUM:   Album      := ReadTextFromStream(aStream);
            MP3DB_DAUER:   fDuration  := ReadIntegerFromStream(aStream);
            MP3DB_BITRATE: fBitrate   := ReadWordFromStream(aStream);
            MP3DB_VBR:     fvbr       := ReadBoolFromStream(aStream);
            MP3DB_CHANNELMODE: begin
                                  fChannelmodeIDX := ReadByteFromStream(aStream);
                                  if fChannelmodeIDX > 4 then
                                      fChannelmodeIDX := 1;
                               end;
            MP3DB_SAMPLERATE:  begin
                                  fSamplerateIDX := ReadByteFromStream(aStream);
                                  if fSamplerateIDX > 9 then
                                      fSamplerateIDX := 7;
                               end;
            MP3DB_FILESIZE  : fFileSize := ReadIntegerFromStream(aStream);
            MP3DB_DATUM     : fFileAge  := ReadDateTimeFromStream(aStream);
            MP3DB_TRACK     : fTrack    := ReadByteFromStream(aStream);    // Byte
            MP3DB_TRACK_INT : fTrack    := ReadIntegerFromStream(aStream); // Word (since 4.13)
            MP3DB_CD        : CD        := ReadTextFromStream(aStream);

            MP3DB_YEAR: begin
                             wYear :=  ReadWordFromStream(aStream);
                             Year := IntToStr(WYear);
                        end;
            MP3DB_GENRE: begin
                             GenreIDX := ReadByteFromStream(aStream);
                             if GenreIDX <= 125 then
                                 genre := ID3Genres[GenreIDX]
                             else
                                 genre := '';
                          end;
            MP3DB_GENRE_STR:     genre    := ReadTextFromStream(aStream);
            MP3DB_LYRICS:        Lyrics   := UTF8String(Trim( ReadTextFromStream(aStream) ));
            MP3DB_ID3KOMMENTAR:  Comment  := ReadTextFromStream(aStream);
            MP3DB_COVERID:       CoverID  := ReadTextFromStream(aStream);
            MP3DB_RATING :       fRating  := ReadByteFromStream(aStream);
            MP3DB_CUEPRESENT :   begin
                                      if JustForPlaylist then
                                      begin
                                          // MP3DB_CUEPRESENT: data is =1 if a cuesheet should be available
                                          // However, this field is only written iff there IS one, so we don't need the value
                                          ReadIntegerFromStream(aStream);
                                          GetCueList;
                                      end else
                                          // No CUE-Support for the Library
                                          ReadIntegerFromStream(aStream);
                                 end;
            MP3DB_FAVORITE :     fFavorite    := ReadByteFromStream(aStream);
            MP3DB_PLAYCOUNTER :  fPlayCounter := ReadCardinalFromStream(aStream);
            MP3DB_DRIVE_ID  :    fDriveID     := ReadIntegerFromStream(aStream);

            MP3DB_LASTFM_TAGS :  RawTagLastFM := UTF8String(ReadTextFromStream(aStream));

            MP3DB_ALBUMGAIN : fAlbumGain := ReadSingleFromStream(aStream);
            MP3DB_TRACKGAIN : fTrackGain := ReadSingleFromStream(aStream);

            MP3DB_ALBUMPEAK : fAlbumPeak := ReadSingleFromStream(aStream);
            MP3DB_TRACKPEAK : fTrackPeak := ReadSingleFromStream(aStream);

            DATA_END_ID: ; // Explicitly do Nothing -  because of the ELSE path ;-)
        else
            begin
                // unknown DataID, use generic reading function
                // if this fails, then the file is invalid, stop reading
                if not ReadUnkownDataFromStream(aStream) then
                    c := DATA_END_ID;
            end;
        end;

    until (DataID = DATA_END_ID) or (c >= DATA_END_ID);
end;

// split the reading method into two methods for loading the (huge) media library file
// keep the old name (just LoadFromStream) for use with *.npl Playlist files
function TAudioFile.LoadSizeInfoFromStream_DEPRECATED(aStream: TStream): Integer;
begin
    aStream.Read(result, SizeOf(result));
end;
procedure TAudioFile.LoadDataFromStream_DEPRECATED(aStream: TStream);
var GenreIDX:byte;
    c: Integer;
    katold:byte;
    tmp: UnicodeString;
    Id: Byte;
    // dummy: Integer;
    Wyear: word;
    DummyInt: Integer;
    Dummystr: UnicodeString;
begin
    // Note: Dummy was used for the size of the Audiofile data
    // not used for some time,
    // in 2018 relocated in seperate function, as the Medialibrary.Load method needs to check the size field for buffering reasons
    //  aStream.Read(dummy, SizeOf(dummy));
    c := 0;
    repeat
        aStream.Read(id, sizeof(ID));
        inc(c);
        case ID of
            MP3DB_PFAD: begin
                tmp := ReadTextFromStream_DEPRECATED(aStream);
                pfad := tmp;
            end;
            MP3DB_ARTIST: Artist := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_TITEL: Titel := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_ALBUM: Album := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_DAUER: aStream.Read(fDuration,SizeOf(fDuration));
            MP3DB_BITRATE: aStream.Read(fBitrate,SizeOf(fBitrate));
            MP3DB_VBR: aStream.Read(fvbr,SizeOf(fvbr));
            MP3DB_CHANNELMODE: begin
                            aStream.Read(fChannelmodeIDX, SizeOf(fChannelModeIDX));
                            if fChannelmodeIDX > 4 then
                                fChannelmodeIDX := 1;
            end;
            MP3DB_SAMPLERATE: begin
                            aStream.Read(fSamplerateIDX,SizeOf(fSamplerateIDX));
                            if fSamplerateIDX > 9 then
                                fSamplerateIDX := 7;
            end;
            MP3DB_FILESIZE: aStream.Read(fFileSize,SizeOf(fFileSize));
            // new again in Nemp 4.0: FileAge
            MP3DB_DATUM : aStream.Read(fFileAge, SizeOf(fFileAge));
            MP3DB_TRACK : aStream.Read(fTrack, SizeOf(fTrack));
            MP3DB_CD    : CD := ReadTextFromStream_DEPRECATED(aStream);    // New in 4.5

            MP3DB_KATEGORIE: aStream.Read(katold,SizeOf(katold));
            MP3DB_YEAR: begin
                aStream.Read(WYear, SizeOf(WYear));
                Year := IntToStr(WYear);
            end;
            MP3DB_GENRE: begin
                aStream.Read(GenreIDX,SizeOf(GenreIDX));
                if GenreIDX <= 125 then
                  genre := ID3Genres[GenreIDX]
                else
                  genre := '';
            end;
            MP3DB_GENRE_STR: genre := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_LYRICS: Lyrics := UTF8String(Trim(  ReadTextFromStream_DEPRECATED(aStream)));
            MP3DB_ID3KOMMENTAR: Comment := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_COVERID: CoverID := ReadTextFromStream_DEPRECATED(aStream);

            MP3DB_RATING : aStream.Read(fRating, sizeOf(fRating));
            MP3DB_CUEPRESENT  : aStream.Read(DummyInt, sizeOf(DummyInt));

            MP3DB_FAVORITE : aStream.Read(fFavorite, sizeOf(fFavorite));
            MP3DB_PLAYCOUNTER  : aStream.Read(fPlayCounter, sizeOf(fPlayCounter));
            MP3DB_DRIVE_ID{MP3DB_DUMMY_Int3}  : aStream.Read(DummyInt, sizeOf(DummyInt));

            MP3DB_LASTFM_TAGS : RawTagLastFM := UTF8String(ReadTextFromStream_DEPRECATED(aStream));
            //MP3DB_DUMMY_Text1 : DummyStr := ReadTextFromStream(aStream);
            //MP3DB_DUMMY_Text2 : DummyStr := ReadTextFromStream(aStream);
            MP3DB_ALBUMGAIN : DummyStr := ReadTextFromStream_DEPRECATED(aStream);

            else begin
              // Something is wrong. Stop reading.
               c := MP3DB_ENDOFINFO;
            end;
        end;
    until (ID = MP3DB_ENDOFINFO) OR (c >= MP3DB_ENDOFINFO);

end;
procedure TAudioFile.LoadFromStream_DEPRECATED(aStream: Tstream);
begin
    LoadSizeInfoFromStream_DEPRECATED(aStream);
    LoadDataFromStream_DEPRECATED(aStream);
end;


{
    --------------------------------------------------------
    LoadFromStreamForPlaylist
    Load AudioFile-structure from stream
    Difference to previous method: Filenames are relative ones.
    Note: Make sure that SetCurrentDir is called before this method!
    !!! Not used in 4.13 any more
    --------------------------------------------------------
}
procedure TAudioFile.LoadFromStreamForPlaylist_DEPRECATED(aStream: TStream);
var GenreIDX:byte;
    c, cuePresent: Integer;
    katold:byte;
    tmp: UnicodeString;
    Id: Byte;
    dummy: Integer;
    Wyear: word;
    DummyInt: Integer;
    Dummystr: UnicodeString;

begin
    aStream.Read(dummy, SizeOf(dummy));
    c := 0;
    repeat
        aStream.Read(id, sizeof(ID));
        inc(c);
        case ID of
            MP3DB_PFAD: begin
                tmp := ReadTextFromStream_DEPRECATED(aStream);
                Pfad := tmp;
                if fAudioType = at_File then
                begin
                    pfad := ExpandFilename(tmp);
                end else
                begin
                    FileIsPresent := True;
                end;
            end;
            MP3DB_ARTIST: Artist := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_TITEL: Titel := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_ALBUM: Album := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_DAUER: aStream.Read(fDuration,SizeOf(fDuration));
            MP3DB_BITRATE: aStream.Read(fBitrate,SizeOf(fBitrate));
            MP3DB_VBR: aStream.Read(fvbr,SizeOf(fvbr));
            MP3DB_CHANNELMODE: aStream.Read(fChannelmodeIDX, SizeOf(fChannelModeIDX));
            MP3DB_SAMPLERATE: aStream.Read(fSamplerateIDX,SizeOf(fSamplerateIDX));
            MP3DB_FILESIZE: aStream.Read(fFileSize,SizeOf(fFileSize));
            // new again in Nemp 4.0: FileAge
            MP3DB_DATUM : aStream.Read(fFileAge, SizeOf(fFileAge));
            MP3DB_TRACK: aStream.Read(fTrack, SizeOf(fTrack));
            MP3DB_CD   : CD := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_KATEGORIE: aStream.Read(katold,SizeOf(katold));
            MP3DB_YEAR: begin
                aStream.Read(WYear, SizeOf(WYear));
                Year := inttostr(WYear);
            end;
            MP3DB_GENRE: begin
                aStream.Read(GenreIDX,SizeOf(GenreIDX));
                if GenreIDX <= 125 then
                  genre := ID3Genres[GenreIDX]
                else
                  genre := '';
            end;
            MP3DB_GENRE_STR: genre := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_LYRICS: Lyrics := Utf8String(Trim(ReadTextFromStream_DEPRECATED(aStream)));
            MP3DB_ID3KOMMENTAR: Comment := ReadTextFromStream_DEPRECATED(aStream);
            MP3DB_COVERID: CoverID := ReadTextFromStream_DEPRECATED(aStream);

            MP3DB_RATING : aStream.Read(fRating, sizeOf(fRating));
            MP3DB_CUEPRESENT  : begin
                                    aStream.Read(cuePresent, sizeOf(cuePresent));
                                    GetCueList;
                                end;
            //MP3DB_DUMMY_Byte2 : aStream.Read(DummyByte, sizeOf(DummyByte));
            MP3DB_FAVORITE : aStream.Read(fFavorite, sizeOf(fFavorite));
            //MP3DB_DUMMY_Int1  : aStream.Read(DummyInt, sizeOf(DummyInt));
            MP3DB_PLAYCOUNTER  : aStream.Read(fPlayCounter, sizeOf(fPlayCounter));
            MP3DB_DRIVE_ID{MP3DB_DUMMY_Int3}  : aStream.Read(DummyInt, sizeOf(DummyInt));
            //MP3DB_DUMMY_Text1 : DummyStr := ReadTextFromStream(aStream);
            MP3DB_LASTFM_TAGS : RawTagLastFM := UTF8String(ReadTextFromStream_DEPRECATED(aStream));
            // MP3DB_DUMMY_Text2 : DummyStr := ReadTextFromStream(aStream);
            MP3DB_ALBUMGAIN : DummyStr := ReadTextFromStream_DEPRECATED(aStream);

            else begin
              c := MP3DB_ENDOFINFO;
            end;
        end;
    until (ID = MP3DB_ENDOFINFO) OR (c >= MP3DB_ENDOFINFO); 
end;


{
    --------------------------------------------------------
    Methods for writing the stuff ...
    --------------------------------------------------------
}

function TAudioFile.SaveToStream(aStream: Tstream; aPath: UnicodeString = ''): LongInt;
var GenreIDXint:integer;
    GenreIDX: byte;
begin
    result := 0;
    if aPath = '' then
    begin
        // for the MediaLibrary
        // write filename incl. path, also the DriveID
        result := result + WriteTextToStream(aStream, MP3DB_PFAD, Pfad);
        result := result + WriteIntegerToStream(aStream, MP3DB_DRIVE_ID, fDriveID);
    end
    else
    begin
        // for the Playlist
        // write only the name in the parameter
        result := result + WriteTextToStream(aStream, MP3DB_PFAD, aPath);
        // also for Playlistfiles: write whether cuesheet is present or not
        if Assigned(CueList) and (CueList.Count > 0) then
            result := result + WriteIntegerToStream(aStream, MP3DB_CUEPRESENT, 1);
    end;

    if length(Artist) > 0 then result := result + WriteTextToStream(aStream, MP3DB_ARTIST, Artist);
    if length(titel) > 0  then result := result + WriteTextToStream(aStream, MP3DB_TITEL, Titel);
    if length(Album) > 0  then result := result + WriteTextToStream(aStream, MP3DB_ALBUM, Album);
    if RawTagLastFM <> '' then result := result + WriteTextToStream(aStream, MP3DB_LASTFM_TAGS, String(RawTagLastFM));

    if Duration <> 0  then result := result + WriteIntegerToStream(aStream, MP3DB_DAUER, fDuration);
    if bitrate <> 192 then result := result + WriteWordToStream(aStream, MP3DB_BITRATE, fBitrate);

    result := result + WriteBoolToStream(aStream, MP3DB_VBR, fvbr);

    if fChannelModeIDX <> 1 then result := result + WriteByteToStream(aStream, MP3DB_CHANNELMODE, fChannelmodeIDX);
    if fSamplerateIDX <> 7  then result := result + WriteByteToStream(aStream, MP3DB_SAMPLERATE, fSamplerateIDX);

    result := result + WriteIntegerToStream(aStream, MP3DB_FILESIZE, fFileSize);
    result := result + WriteDateTimeToStream(aStream, MP3DB_DATUM, fFileAge);

    // New in  4.13: Support for Track-Values beyond the Byte-Limit
    if Track >= 0 then
    begin
        if Track < 255 then
            result := result + WriteByteToStream(aStream, MP3DB_TRACK, Track)
        else
            result := result + WriteIntegerToStream(aStream, MP3DB_TRACK_INT, Track)
    end;

    if CD <> ''          then result := result + WriteTextToStream(aStream, MP3DB_CD, CD);
    if fRating <> 0      then result := result + WriteByteToStream(aStream, MP3DB_RATING, fRating);
    if fPlayCounter <> 0 then result := result + WriteCardinalToStream(aStream, MP3DB_PLAYCOUNTER, fPlayCounter);
    if fFavorite <> 0    then result := result + WriteByteToStream(aStream, MP3DB_FAVORITE, fFavorite);
    if Year <> ''        then result := result + WriteWordToStream(aStream, MP3DB_YEAR, StrToIntDef(Year, 0));

    GenreIDXint := ID3Genres.IndexOf(Genre);
    if GenreIDXint = -1 then
          // No Standard-Genre - write String
          result := result + WriteTextToStream(aStream, MP3DB_GENRE_STR, Genre)
    else
    begin
          // Standard-Genre: just write the corresponding byte
          GenreIDX := Byte(GenreIDXint);
          result := result + WriteByteToStream(aStream, MP3DB_GENRE, GenreIDX);
    end;

    if length(lyrics) > 0  then result := result + WriteTextToStream(aStream, MP3DB_LYRICS, String(lyrics));
    if length(Comment) > 0 then result := result + WriteTextToStream(aStream, MP3DB_ID3KOMMENTAR, Comment);
    if CoverID <> ''       then result := result + WriteTextToStream(aStream, MP3DB_COVERID, CoverID);

    if not isZero(fAlbumGain) then result := result + WriteSingleToStream(aStream, MP3DB_ALBUMGAIN, fAlbumGain);
    if not isZero(fTrackGain) then result := result + WriteSingleToStream(aStream, MP3DB_TRACKGAIN, fTrackGain);
    if not SameValue(fAlbumPeak, 1) then result := result + WriteSingleToStream(aStream, MP3DB_ALBUMPEAK, fAlbumPeak);
    if not SameValue(fTrackPeak, 1) then result := result + WriteSingleToStream(aStream, MP3DB_TRACKPEAK, fTrackPeak);

    // end of AudioFile
    result := result + WriteDataEnd(aStream);
end;



{ TErrorLog }

constructor TErrorLog.create(aAction: TAudioFileAction; aFile: TAudioFile;
  aErr: TNempAudioError; aImportant: Boolean);
begin
    Action := aAction;
    AudioFile := aFile;
    Error := aErr ;
    Important := aImportant;
end;

initialization

// Set the DefaultRatingDescription for MP3FileUtils
DefaultRatingDescription := 'Nemp - Noch ein MP3-Player, www.gausi.de';



end.
