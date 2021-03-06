//AQUATOX SOURCE CODE Copyright (c) 2005-2014 Eco Modeling and Warren Pinnacle Consulting, Inc.
//Code Use and Redistribution is Subject to Licensing, SEE AQUATOX_License.txt
// 
unit ExcelFuncs;

interface

Uses Excel2000, Controls;

Type
  TExcelOutput = Class
    lcid: integer;
    Res: variant;
    WBk: _WorkBook;
    WS: _Worksheet;
    Excel: _Application;
    Unknown: IUnknown;
    FileN: String;
    AppWasRunning: boolean;
    Threadsafe: Boolean;
    SaveIter: Integer;
    Constructor Create(TS: Boolean);
    Function GetSaveName(FName, TString: String): Boolean;
    Procedure Save;
    Destructor SaveandClose;
    Function OpenFiles: Boolean;
    Procedure CloseFiles;
    Destructor Close;
  End;

implementation

Uses Dialogs, SysUtils, Variants, OLECtrls, ComObj, Windows, ExtCtrls, ActiveX, Forms;

Constructor TExcelOutput.Create(TS: Boolean);
Begin
  Threadsafe := TS;
  Inherited Create;
  SaveIter := 0;
End;

Function TExcelOutput.OpenFiles : Boolean;
Begin
    Result := True;
    lcid := LOCALE_USER_DEFAULT;

    Try

      Excel := CoExcelApplication.Create;
      Excel.Interactive[LCID] := False;

    Except
      If not ThreadSafe then
        MessageDlg('Error Starting or Accessing Excel, Excel must be Installed to Use These Functions',mterror,[mbOK],0);

      Result := False;
      Close;
      Exit;
    End;  {Except}

    Excel.Visible[lcid] := False;

    WBk := Excel.WorkBooks.Add(xlWBATWorksheet,LCID);
    WS := Excel.ActiveSheet as _Worksheet;
End;

Function TExcelOutput.GetSaveName(FName,TString: String): Boolean;
Var SaveDialog: TSaveDialog;
    PCFileN: array[0..300] of Char;

begin
    SaveDialog := TSaveDialog.Create(nil);
    with SaveDialog do // Create save dialog and set its options
    begin
       DefaultExt := 'xls' ;
       Filter := 'Excel files (*.xls*)|*.xls*|All files (*.*)|*.*' ;
       Options := [ofOverwritePrompt,ofPathMustExist,ofNoReadOnlyReturn,ofHideReadOnly] ;
       Title := TString;
       FileName := FName;
    end;

  GetSaveName := SaveDialog.Execute;
  FileN := SaveDialog.FileName;
  SaveDialog.Free;

  IF Result then
    Begin
      If FileExists(FileN) then
         Begin
           StrPCopy(PCFileN,FileN);
           If Not DeleteFile(PCFileN) then
             Begin
               If Not Threadsafe then
                  MessageDlg('File cannot be accessed.  May be in use by another application.',mterror,[mbok],0);
               GetSaveName := False;
               Close;
               Exit;
             End;
         End;

      Result := OpenFiles;
    End;

  If Not Result then Close;

end;

Procedure TExcelOutput.Save;
Begin
  Inc(SaveIter);
  Try
    If SaveIter = 1 then
      Begin
        if StrToFloat(Excel.Version[LCID]) > 11
          Then  Wbk.SaveAs(FileN,56,EmptyParam,EmptyParam,EmptyParam
                          ,EmptyParam,xlnochange,EmptyParam,EmptyParam,EmptyParam,EmptyParam,LCID)
          else  Wbk.SaveAs(FileN,EmptyParam,EmptyParam,EmptyParam,EmptyParam
                   ,EmptyParam,xlnochange,EmptyParam,EmptyParam,EmptyParam,EmptyParam,LCID);
      End
    else
       Begin
         Wbk.Save(LCID);
       End;
  Except
  End;
End;


Destructor TExcelOutput.SaveandClose;
Begin
  Try
   Save;
   Excel.Interactive[LCID] := True;
   If Threadsafe then Excel.Visible[lcid] := True
                 else If MessageDlg('View your Excel File now?',mtconfirmation,[mbyes,mbno],0) = MRNo
                          then CloseFiles
                          else Excel.Visible[lcid] := True;

  Except
    CloseFiles;
  End;

End;


Procedure TExcelOutput.CloseFiles;
Begin
    Wbk.Close(False,EmptyParam,EmptyParam,LCID);
    If not AppWasRunning then Excel.Quit

End;

Destructor TExcelOutput.Close;
Begin
  Inherited;
End;

end.
