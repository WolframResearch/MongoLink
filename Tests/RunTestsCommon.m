(* auxiliary test functions *)

runOneTestTF[file_String, dir_String] := Module[
   {success = True, report, failed, ffile = FileNameJoin[{dir, file}]}
   ,
   If[Not@FileExistsQ[ffile],
      Print[">>> Test file ", ffile, " does not exist"];
      Return[False]
   ];
   report = TestReport[ffile];
   If[Not@report["AllTestsSucceeded"],
      success = False;
      Print[">>> Tests failed: ", report["TestsFailedIndices"]];
      failed = report["TestsFailedWrongResults"];
      Print[Map[#[{"ExpectedOutput", "ActualOutput"}] &, failed]];
   ];
   success
];

runOneTest[file_String, dir_String] :=
        If[runOneTestTF[file, dir], "Success!", "Failures!"];

runAllTests[] := Module[
   {success, files, i}
   ,
   files = FileNames["*.wlt", NotebookDirectory[], Infinity];
   success = True;
   Do[
      Print[FileNameTake@files[[i]]];
      success = And[success, runOneTestTF[files[[i]], ""]];
     ,
      {i, Length@files}
   ];
   If[success, "Success!", "Failures!"]
];

