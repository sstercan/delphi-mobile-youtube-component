unit XYoutube;
{- Unit Info----------------------------------------------------------------------------
Unit Name  : XYoutube
Created By : Barýþ Atalay 13/10/2014
Last Change By :

Web Site: http://brsatalay.blogspot.com.tr/

Notes: Thanks to "Ali Zairov" for helping.
----------------------------------------------------------------------------------------}

interface

Uses System.Classes, System.SysUtils, System.Types
    ,FMX.Listbox
    ,IdHTTP, IdComponent
    ,XSuperObject
    ,Generics.Collections;

type
  TOnDownload = procedure (Percent:Single; WorkingByte: Int64 )of object ;

  TInformations = class
    Size,
    VideoLink,
    MimeType,
    Quality: String;
  end;

  TYoutube = class(TComponent)
    private type
      TDownloadThread = class(TThread)
        private
          FHttp: TIdHTTP;
          FOwner: TYoutube;
          FUrl: String;
          procedure HttpWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
          procedure Execute; override;
        public
          constructor Create(AOwner: TYoutube; Link: String);
          destructor  Destroy; override;
      end;
    private
      FInformations: TObjectList<TInformations>;
      YHTTP: TIdHTTP;
      FInf: TInformations;
      FFormatList,
      FTitle,
      FLengthS,
      FFolder,
      FYTId: String;
      FCombo: TComboBox;
      FOnDownload: TOnDownload;
      FDesign: Boolean;
      function  GetId: String;
      procedure SetId(const Value: String);
      procedure GetInformation(ID: String);
      procedure DoParse(const Text: String);
      function  GetTitle: String;
      procedure SetTitle(const Value: String);
      procedure FClosePopup(Sender: TObject);
      procedure XClosePopup(Sender: TObject);
      procedure PlayVideo(Link: String);
      procedure DownloadVideo(Link: String);
      class function Split(const Input: string; const Delimiter: Char): TStringDynArray;
      class function SecToTime(Sec: Integer): string;
      function GetItem(const Index: Integer): TInformations;
      function GetSize: String;
      function GetAuthor: String;
      function GetSite: String;
      function GetVersion: String;
      function GetDes: Boolean;
      procedure SetDes(const Value: Boolean);
    public
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      procedure Get;
      procedure Play;
      procedure Download;
      property DownloadFolder              : String      read FFolder     write FFolder;
      property Items[const Index: Integer] : TInformations read GetItem;    default;
      function Count: Integer;
    published
      property Title          : String      read GetTitle;
      property YouTubeId      : String      read GetId       write SetId;
      property OnDownload     : TOnDownload read FOnDownload write FOnDownload;
      property VideoSize      : String      read GetSize;
      property Author         : String      read GetAuthor;
      property Site           : String      read GetSite;
      property GetDesign      : Boolean     read GetDes      write SetDes;
      property Version        : String      read GetVersion;
  end;

procedure Register;

implementation

Uses HTTPApp, FMX.Dialogs
{$IFDEF ANDROID}
  ,Androidapi.JNI.GraphicsContentViewText
  ,Androidapi.Helpers
  ,FMX.Platform.Android
  ,Androidapi.JNI.Net
{$ELSE}
  ,Windows
  ,ShellApi
{$ENDIF}

;

procedure Register;
begin
  RegisterComponents('Android', [TYouTube]);
end;

{ TYoutube }

function TYoutube.Count: Integer;
begin
  Result := FInformations.Count;
end;

constructor TYoutube.Create(AOwner: TComponent);
begin
  inherited;
  FInformations := TObjectList<TInformations>.Create;
  YHTTP         := TIdHTTP.Create(Self);
  YHTTP.Request.Accept := '*/*';
  YHTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 6.1) Gecko/20130101 Firefox/21.0';
  YHTTP.Request.Host := 'www.youtube.com';
  FCombo        := TComboBox.Create(Self);
  FDesign       := True;
end;

destructor TYoutube.Destroy;
begin
  FCombo.Free;
  YHTTP.Free;
  FInformations.Free;
  inherited;
end;

procedure TYoutube.DoParse(const Text: String);
var
  Content, xText: string;
  P, I1, I2: Integer;
  X: ISuperObject;
  A1, A2, A3: TStringDynArray;
  F1, F2: TStringDynArray;
  Text1, Text2: string;
begin
  Content := Text;
  xText := 'ytplayer.config = ';
  P := Pos(xText, Content);
  if P = 0 then Exit;
  Content := Copy(Content, P + Length(xText), MaxInt);
  P := Pos('</script>', Content);
  if P = 0 then Exit;
  Content := Trim(Copy(Content, 1, P - 1));
  X := SO(Content);
  try
    FTitle := X['args."title"'].AsString;
    FFormatList := X['args."fmt_list"'].AsString;
    FLengthS := X['args."length_seconds"'].AsString;
    Content := X['args."url_encoded_fmt_stream_map"'].AsString;
  finally
    X := nil;
  end;

  A1 := Split(Content, ',');
  F1 := Split(FFormatList, ',');
  FCombo.Clear;
  for I1 := System.Low(A1) to System.High(A1) do
  begin
    Text1 := A1[I1];
    A2 := Split(Text1, '&');
    FInf := TInformations.Create;
    F2 := Split(F1[I1], '/');

    if Length(F2) > 1 then
      FInf.Size := F2[1];

    for I2 := System.Low(A2) to System.High(A2) do
    begin
      Text2 := A2[I2];
      A3 := Split(Text2, '=');
      if A3[0] = 'url' then
        FInf.VideoLink := string(HTTPDecode(String(A3[1])))
      else if A3[0] = 'quality' then
        FInf.Quality := A3[1]
      else if A3[0] = 'type' then
        FInf.MimeType := string(HTTPDecode(String(A3[1])))
    end;

    if FCombo.items.indexof(FInf.Size + ' ' + FInf.Quality) = -1 then
    begin
      FCombo.Items.Add(FInf.Size + ' ' + FInf.Quality);
      FInformations.Add(FInf);
    end;
  end;
end;

procedure TYoutube.Download;
begin
  Get;
  FCombo.OnClosePopup := xClosePopup;
  FCombo.DropDown;
end;

procedure TYoutube.DownloadVideo(Link: String);
var
  FIslem: TDownloadThread;
begin
  FIslem := TDownloadThread.Create(Self,Link);
  FIslem.FreeOnTerminate := True;
  FIslem.Start;
end;

procedure TYoutube.FClosePopup(Sender: TObject);
var
  TempCombo: TComboBox;
begin
  if not (Sender is TComboBox) then Exit;

  TempCombo := (Sender as TComboBox);

  if TempCombo = nil then Exit;

  if TempCombo.ItemIndex = -1 then Exit;

  PlayVideo(FInformations.Items[TempCombo.ItemIndex].VideoLink);
end;

procedure TYoutube.Get;
begin
  if Trim(FYTId) <> '' then
    GetInformation(YouTubeId);
end;

function TYoutube.GetAuthor: String;
begin
  Result := 'Barýþ Atalay';
end;

function TYoutube.GetDes: Boolean;
begin
  Result := FDesign;
end;

function TYoutube.GetId: String;
begin
  Result := FYTId;
end;

procedure TYoutube.GetInformation(ID: String);
var Url: String;
begin
  URL := 'http://www.youtube.com/watch?v=' + ID;
  YHTTP.Request.Referer := URL;
  DoParse(YHTTP.Get(URL));
end;

function TYoutube.GetItem(const Index: Integer): TInformations;
begin
  Result := FInformations.Items[Index];
end;

function TYoutube.GetSite: String;
begin
  Result := 'http://brsatalay.blogspot.com.tr/';
end;

function TYoutube.GetSize: String;
begin
  if not FLengthS.Trim.IsEmpty then
    Result := SecToTime(FLengthS.ToInteger);
end;

function TYoutube.GetTitle: String;
begin
  Result := FTitle;
end;

function TYoutube.GetVersion: String;
begin
  Result := '1.0'
end;

procedure TYoutube.Play;
begin
  Get;
  FCombo.OnClosePopup := FClosePopup;
  FCombo.DropDown;
end;

procedure TYoutube.PlayVideo(Link: String);
{$IFDEF ANDROID}
var
  Intent: JIntent;
  Data: Jnet_Uri;
  CompName: JComponentName;
begin
  Data := TJnet_Uri.JavaClass.parse(StringToJString(Link));
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_VIEW);

  CompName := TJComponentName.JavaClass.init(StringToJString('android'),
    StringToJString('com.android.internal.app.ResolverActivity'));
  Intent.setComponent(CompName);
  Intent.setDataAndType(Data, StringToJString('video/mp4'));
  try
    MainActivity.startActivity(Intent);
  except
    on E: Exception do
  begin
    ShowMessage(E.Message);
  end;
 end;
{$ELSE}
begin
  ShellExecute(0,'open',     PChar(Link), nil, nil, SW_SHOWNORMAL) ;
{$ENDIF}
end;

class function TYoutube.SecToTime(Sec: Integer): string;
var
   H, M, S: string;
   ZH, ZM, ZS: Integer;
begin
   ZH := Sec div 3600;
   ZM := Sec div 60 - ZH * 60;
   ZS := Sec - (ZH * 3600 + ZM * 60) ;
   H := IntToStr(ZH) ;
   M := IntToStr(ZM) ;
   S := IntToStr(ZS) ;
   Result := H + ':' + M + ':' + S;
end;

procedure TYoutube.SetDes(const Value: Boolean);
begin
  if Value <> FDesign then
    FDesign := Value;
end;

procedure TYoutube.SetId(const Value: String);
begin
  FYTId := Value;

  if csDesigning in ComponentState then
    if (not FDesign) or (Value.Trim.IsEmpty) then
      Exit;
  Get;
end;

procedure TYoutube.SetTitle(const Value: String);
begin
  if Value <> FTitle then
    FTitle := Value;
end;

class function TYoutube.Split(const Input: string;
  const Delimiter: Char): TStringDynArray;
var
  Strings: TStrings;
  Index: Integer;
begin
  Strings := TStringList.Create;
  try
    Strings.StrictDelimiter := True;
    Strings.Delimiter := Delimiter;
    Strings.DelimitedText := Input;
    SetLength(Result, Strings.Count);
    for Index := 0 to Strings.Count - 1 do
      Result[Index] := Strings[Index];
  finally
    Strings.Free;
  end;
end;

procedure TYoutube.XClosePopup(Sender: TObject);
var
  TempCombo: TComboBox;
begin
  if not (Sender is TComboBox) then Exit;

  TempCombo := (Sender as TComboBox);

  if TempCombo = nil then Exit;

  if TempCombo.ItemIndex = -1 then Exit;

  DownloadVideo(FInformations.Items[TempCombo.ItemIndex].VideoLink);
end;

{ TYoutube.TDownloadThread }

constructor TYoutube.TDownloadThread.Create(AOwner: TYoutube; Link: String);
begin
  inherited Create(True);
  FOwner       := AOwner;
  FHttp        := TIdHTTP.Create(nil);
  FHttp.OnWork := HttpWork;
  FUrl         := Link;
end;

destructor TYoutube.TDownloadThread.Destroy;
begin
  FHttp.Disconnect;
  FHttp.Free;
  inherited;
end;

procedure TYoutube.TDownloadThread.Execute;
var
  MS: TMemoryStream;
  S: String;
begin
  inherited;
  if Trim(FOwner.FFolder) = '' then
    raise Exception.create('Download folder could not be found!');

  FHttp.Request.Accept := '*/*';
  FHttp.Request.UserAgent := 'Mozilla/5.0 (Windows NT 6.1) Gecko/20130101 Firefox/21.0';
  FHttp.Request.Host := 'www.youtube.com';

  MS := TMemoryStream.Create;
  try
    FHttp.Get(FUrl,MS);
    MS.Seek(0,soFromBeginning);

    if FOwner.FFolder[Length(FOwner.FFolder)] <> PathDelim then
      S := FOwner.FFolder + PathDelim
    else
      S := FOwner.FFolder;

    MS.SaveToFile(S + FOwner.FTitle + '.mp4');
  finally
    MS.Free;
  end;
end;

procedure TYoutube.TDownloadThread.HttpWork(ASender: TObject;
  AWorkMode: TWorkMode; AWorkCount: Int64);
var
  Http: TIdHTTP;
  ContentLength: Int64;
  FPercent: Single;
begin
  Http := TIdHTTP(ASender);
  ContentLength := Http.Response.ContentLength;

  if (Pos('chunked', LowerCase(Http.Response.TransferEncoding)) = 0) and
     (ContentLength > 0) then
  begin
    FPercent        := 100 * AWorkCount div ContentLength;
    if Assigned(FOwner.FOnDownload) then
      FOwner.FOnDownload(FPercent,AWorkCount);
  end;
end;

end.
