## Errata
- Number.NegativeInfinity: This returns a constant value that represents 1 divided by 0. should be Number.NegativeInfinity: This returns a constant value that represents -1 divided by 0. on Page 117.
- Page 377 shows the custom function:  

  ( table as table, newColumnName as text, lookupTable as table, lookupColumnName<br>
  as text ) as table =><br>
  Table.AddColumn(<br>
  table,<br>
  newColumnName,<br>
  each if List.Contains(<br>
  Table.Column( lookupTable, lookupColumnName),<br>
  Record.Field( table, "Product" ) )<br>
  then true else false )<br>
  
  
  A mistake is in there. The line 'Record.Field( table, "Product" ) )' returns an error. 
  
  The actual code should be like below (with a change on both the first line, and the line before the last one): 
  
  ( table as table, newColumnName as text, searchColumn as text, lookupTable as table, lookupColumnName<br>
  as text) as table =><br>
  Table.AddColumn(<br>
    table,<br>
    newColumnName,<br>
    each if List.Contains(<br>
    Table.Column( lookupTable, lookupColumnName),<br>
      Record.Field( _, searchColumn ) )<br>
    then true else false )<br>

- Page 378 has: 
  On line 3 the variable is called 'List'. It should be called 'FilteredList'
