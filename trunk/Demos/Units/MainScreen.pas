unit MainScreen;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, XYoutube,
  FMX.StdCtrls, FMX.Memo, FMX.Layouts, FMX.Objects;

type
  TForm3 = class(TForm)
    Button1: TButton;
    Text1: TText;
    ProgressBar1: TProgressBar;
    Button2: TButton;
    Image1: TImage;
    Memo1: TMemo;
    Youtube1: TYoutube;
    procedure Button1Click(Sender: TObject);
    procedure Youtube1Download(Percent: Single; WorkingByte: Int64);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.fmx}
Uses System.IOUtils;

procedure TForm3.Button1Click(Sender: TObject);
var I: Integer;
begin
  ProgressBar1.Value := 0;
  Text1.Text         := '0%';
  Memo1.Text := Memo1.Text + Youtube1.Title + #13 + #10;
  Memo1.Text := Memo1.Text + Youtube1.VideoSize + #13 + #10;
  for I := 0 to Youtube1.Count -1 do
  begin
    Memo1.Text := Memo1.Text + 'Size: ' + Youtube1.Items[I].Size + #13 + #10;
    Memo1.Text := Memo1.Text + 'Quality: ' + Youtube1.Items[I].Quality + #13 + #10;
    Memo1.Text := Memo1.Text + 'Link: ' + Youtube1.Items[I].VideoLink + #13 + #10;
    Memo1.Text := Memo1.Text + 'Type: ' + Youtube1.Items[I].MimeType + #13 + #10;
    Memo1.Text := Memo1.Text + '-------------------------------' + #13 + #10;
  end;
  Youtube1.DownloadFolder := System.IOUtils.TPath.GetDocumentsPath + PathDelim ;
  Youtube1.Download;
end;

procedure TForm3.Button2Click(Sender: TObject);
begin
  Youtube1.Play;
end;

procedure TForm3.Youtube1Download(Percent: Single; WorkingByte: Int64);
begin
  ProgressBar1.Value := Percent;
  Text1.Text := Percent.ToString + '%';
end;

end.
