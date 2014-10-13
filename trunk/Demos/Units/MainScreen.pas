unit MainScreen;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, XYoutube,
  FMX.StdCtrls, FMX.Objects;

type
  TForm3 = class(TForm)
    Youtube1: TYoutube;
    Button1: TButton;
    Image1: TImage;
    Text1: TText;
    ProgressBar1: TProgressBar;
    Button2: TButton;
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
begin
  ProgressBar1.Value := 0;
  Text1.Text         := '0%';
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
