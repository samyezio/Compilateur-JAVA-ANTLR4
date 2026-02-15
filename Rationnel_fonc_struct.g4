grammar Rationnel;

@header {
    import java.util.Map;
    import java.util.HashMap;
    import java.util.List;
    import java.util.ArrayList;
}

@members {
    int labnum = 0;
    int currentAddr = 20;
    boolean isLocal = false;
    int currentLocalAddr = 0;
    int currentParamSize = 0;
    String currentFuncReturnType = "";

    // Tables des Symboles
    Map<String, Integer> symTable = new HashMap<>();      
    Map<String, String> typeTable = new HashMap<>();      
   
    Map<String, Integer> localSymTable = new HashMap<>();  
    Map<String, String> localTypeTable = new HashMap<>();  

    // Tables pour les Structures (Bonus 3.3)
    Map<String, Integer> structSizes = new HashMap<>();
    Map<String, Map<String, Integer>> structFields = new HashMap<>();
    Map<String, Map<String, String>> structFieldTypes = new HashMap<>();

    class FuncSignature {
        String returnType;
        List<String> paramTypes;
        String label;
        int totalParamSlots;
        public FuncSignature(String rt, List<String> pt, String l, int slots) {
            this.returnType = rt; this.paramTypes = pt; this.label = l; this.totalParamSlots = slots;
        }
    }
    Map<String, FuncSignature> funcTable = new HashMap<>();

    String newLabel() { return "L" + (labnum++); }

    boolean isVar(String id) {
        if (isLocal && localSymTable.containsKey(id)) return true;
        return symTable.containsKey(id);
    }

    void checkVar(String id) {
        if (!isVar(id))
            throw new RuntimeException("Erreur sémantique : Variable '" + id + "' non déclarée.");
    }

    String getType(String id) {
        if (isLocal && localTypeTable.containsKey(id)) return localTypeTable.get(id);
        checkVar(id);
        return typeTable.get(id);
    }
   
    String getFuncType(String id) {
        if (funcTable.containsKey(id)) return funcTable.get(id).returnType;
        return null;
    }

    String getPushInst(String id) {
        if (isLocal && localSymTable.containsKey(id)) return "PUSHL " + localSymTable.get(id) + "\n";
        checkVar(id);
        return "PUSHG " + symTable.get(id) + "\n";
    }

    String getStoreInst(String id, int offset) {
        if (isLocal && localSymTable.containsKey(id)) return "STOREL " + (localSymTable.get(id) + offset) + "\n";
        checkVar(id);
        return "STOREG " + (symTable.get(id) + offset) + "\n";
    }

   void declareVar(String id, String type) {
        int size = 1;
        if (type.equals("RAT")) size = 2;
        else if (structSizes.containsKey(type)) size = structSizes.get(type);

        if (isLocal) {
            if (localSymTable.containsKey(id)) throw new RuntimeException("Variable locale '" + id + "' déjà déclarée.");
            if (currentLocalAddr < 4) currentLocalAddr = 4;
           
            localSymTable.put(id, currentLocalAddr);
            localTypeTable.put(id, type);
            currentLocalAddr += size;
        } else {
             if (symTable.containsKey(id)) throw new RuntimeException("Variable globale '" + id + "' déjà déclarée.");
             symTable.put(id, currentAddr);
             typeTable.put(id, type);
             currentAddr += size;
        }
    }
}

// --- STRUCTURE DU PROGRAMME ---
start returns [String code]
    @init {
        $code = "ALLOC 200\n";
       
        String FIN_X = newLabel();
        String FIN_Y = newLabel();
        String FIN_BOUCLE = newLabel();
        String ETIQ = newLabel();
        String DEB_BOUCLE = newLabel();
       
        // --- FONCTIONS PRE-IMPLEMENTEES ---
        String function_pgcd =
            "LABEL function_pgcd\n" +
            "PUSHL -3\n" +
            "JUMPF " + FIN_X + "\n" +
            "PUSHL -4\n" +
            "JUMPF " + FIN_Y + "\n" +
            "LABEL " + DEB_BOUCLE + "\n" +
            "PUSHL -3\n" +
            "PUSHL -4\n" +
            "NEQ\n" +
            "JUMPF " + FIN_BOUCLE + "\n" +
            "PUSHL -3\n" +
            "PUSHL -4\n" +
            "INF\n" +
            "JUMPF " + ETIQ + "\n" +
            "PUSHL -4\n" +
            "PUSHL -3\n" +
            "SUB\n" +
            "STOREL -4\n" +
            "JUMP " + DEB_BOUCLE + "\n" +
            "LABEL " + ETIQ + "\n" +
            "PUSHL -3\n" +
            "PUSHL -4\n" +
            "SUB\n" +
            "STOREL -3\n" +
            "JUMP " + DEB_BOUCLE + "\n" +
            "LABEL " + FIN_BOUCLE + "\n" +
            "PUSHL -4\n" +
            "STOREL -5\n" +
            "RETURN\n" +
            "LABEL " + FIN_X + "\n" +
            "PUSHL -4\n" +
            "STOREL -5\n" +
            "RETURN\n" +
            "LABEL " + FIN_Y + "\n" +
            "PUSHL -3\n" +
            "STOREL -5\n" +
            "RETURN\n";

        String function_ppcm =
            "LABEL function_ppcm\n" +
            "PUSHL -3\n" +
            "PUSHL -4\n" +
            "MUL\n" +
            "PUSHI 1\n" +
            "PUSHL -3\n" +
            "PUSHL -4\n" +
            "CALL function_pgcd\n" +
            "POP\n" +
            "POP\n" +
            "DIV \n" +
            "STOREL -5\n" +
            "RETURN \n";

        String function_simp =
            "LABEL function_simp\n" +
            "PUSHI 1\n" +
            "PUSHL -3\n" +
            "PUSHL -4\n" +
            "CALL function_pgcd\n" +
            "POP\n" +
            "POP\n" +
            "PUSHL -3\n" +
            "PUSHL 0\n" +
            "DIV\n" +
            "PUSHL -4\n" +
            "PUSHL 0\n" +
            "DIV\n" +
            "STOREL -6\n" +
            "STOREL -5\n" +
            "RETURN\n";

        String function_proche =
            "LABEL function_proche\n" +
            "PUSHL -3\n" +
            "PUSHI 2\n" +
            "DIV\n" +
            "STOREL -5\n" +
            "PUSHL -4\n" +
            "PUSHL -5\n" +
            "ADD\n" +
            "STOREL -5\n" +
            "PUSHL -5\n" +
            "PUSHL -3\n" +
            "DIV\n" +
            "STOREL -5\n" +
            "RETURN\n";
           
        $code += "JUMP Start\n";
        $code += function_pgcd + function_simp + function_ppcm + function_proche;
    }
    : (s=structDef)* // 1. Structures
      (f=funcDef { $code += $f.code; })* // 2. Fonctions
      { $code += "LABEL Start\n"; }
      (d=decl { $code += $d.code; })* // 3. Globales
      (st=stmt { $code += $st.code; })* // 4. Instructions
      EOF
    {
        $code += "HALT\n";            
        System.out.println($code);
    }
;

// --- DEFINITION STRUCTURE ---
structDef returns [String code]
    @init {
        $code = "";
        String structName = "";
        Map<String, Integer> fields = new HashMap<>();
        Map<String, String> fTypes = new HashMap<>();
        int currentOffset = 0;
    }
    : 'structure' id=ID
      {
        structName = $id.text;
        if(structSizes.containsKey(structName)) throw new RuntimeException("Structure déjà définie");
      }
      '{'
      (
         t=typeVar fId=ID SEMI
         {
             String fType = "INT";
             int size = 1;
             
             if ($t.text.equals("rationnel")) { fType = "RAT"; size = 2; }
             else if ($t.text.equals("entier")) { fType = "INT"; size = 1; }
             else if ($t.text.equals("booleen")) { fType = "BOOL"; size = 1; }
             else {
                 if(!structSizes.containsKey($t.text)) throw new RuntimeException("Type inconnu: "+$t.text);
                 fType = $t.text;
                 size = structSizes.get(fType);
             }

             fields.put($fId.text, currentOffset);
             fTypes.put($fId.text, fType);
             currentOffset += size;
         }
      )+
      '}'
      {
          structSizes.put(structName, currentOffset);
          structFields.put(structName, fields);
          structFieldTypes.put(structName, fTypes);
      }
;

// --- DEFINITION FONCTION ---
funcDef returns [String code]
    @init {
        $code = "";
        List<String> pTypes = new ArrayList<>();
        List<String> pNames = new ArrayList<>();
        int paramSlotCount = 0;
    }
    : typeR=typeVar id=ID
      {
          String fName = $id.text;
          String retType = "";
          if ($typeR.text.equals("rationnel")) retType = "RAT";
          else if ($typeR.text.equals("entier")) retType = "INT";
          else if ($typeR.text.equals("booleen")) retType = "BOOL";
          else retType = $typeR.text;
         
          if (funcTable.containsKey(fName)) throw new RuntimeException("Fonction déjà définie");
          isLocal = true;
          localSymTable.clear();
          localTypeTable.clear();
          currentLocalAddr = 4;
          currentFuncReturnType = retType;
      }
      '('
        ( t1=typeVar id1=ID
          {
             String t = $t1.text.equals("rationnel") ? "RAT" : ($t1.text.equals("entier") ? "INT" : ($t1.text.equals("booleen") ? "BOOL" : $t1.text));
             pTypes.add(t);
             pNames.add($id1.text);
             int sz = 1;
             if(t.equals("RAT")) sz=2; else if(structSizes.containsKey(t)) sz=structSizes.get(t);
             paramSlotCount += sz;
          }
          ( ',' t2=typeVar id2=ID
            {
               String tNext = $t2.text.equals("rationnel") ? "RAT" : ($t2.text.equals("entier") ? "INT" : ($t2.text.equals("booleen") ? "BOOL" : $t2.text));
               pTypes.add(tNext);
               pNames.add($id2.text);
               int szNext = 1;
               if(tNext.equals("RAT")) szNext=2; else if(structSizes.containsKey(tNext)) szNext=structSizes.get(tNext);
               paramSlotCount += szNext;
            }
          )* )? ')'
      {
          String fLabel = "F_" + fName;
          currentParamSize = paramSlotCount;
          funcTable.put(fName, new FuncSignature(retType, new ArrayList<>(pTypes), fLabel, paramSlotCount));
         
          int currentParamOffset = -3;
          for (int i = pNames.size() - 1; i >= 0; i--) {
              String pName = pNames.get(i);
              String pType = pTypes.get(i);
              int sz = 1;
              if(pType.equals("RAT")) sz=2; else if(structSizes.containsKey(pType)) sz=structSizes.get(pType);
             
              currentParamOffset -= (sz - 1);
              localSymTable.put(pName, currentParamOffset);
              localTypeTable.put(pName, pType);
              currentParamOffset -= 1;
          }
          $code += "LABEL " + fLabel + "\n";
      }
      '{' { $code += "ALLOC 50\n"; } (d=decl { $code += $d.code; })* (s=stmt { $code += $s.code; })* '}'
      {
          isLocal = false;
          $code += "RETURN\n";
      }
;

decl returns [String code]
    @init { $code = ""; }
    : t=typeVar
      d1=decl_atom[$t.text] { $code += $d1.code; }
      ( ',' d2=decl_atom[$t.text] { $code += $d2.code; } )* SEMI
;

decl_atom [String tVarRaw] returns [String code]
    @init {
        $code = "";
        String tVar = $tVarRaw;
        if(tVar.equals("entier")) tVar="INT";
        else if(tVar.equals("rationnel")) tVar="RAT";
        else if(tVar.equals("booleen")) tVar="BOOL";
    }
    : id=ID { declareVar($id.text, tVar); }
      ( '=' e=expr
        {
            if (tVar.equals("INT") && $e.type != null && $e.type.equals("RAT")) { $code = $e.code + "POP\n"; }
            else if (tVar.equals("RAT") && $e.type != null && $e.type.equals("INT")) { $code = $e.code + "PUSHI 1\n"; }
            else { $code = $e.code; }

            if (tVar.equals("RAT")) {
                $code += getStoreInst($id.text, 1);
                $code += getStoreInst($id.text, 0);
            }
            else {
                $code += getStoreInst($id.text, 0);
            }
        }
      )?
;

typeVar : 'entier' | 'booleen' | 'rationnel' | ID ;

stmt returns [String code]
    : a=affiche SEMI       { $code = $a.code; }
    | aff=affectation SEMI { $code = $aff.code; }
    | c=condition          { $code = $c.code; }
    | l=loop               { $code = $l.code; }
    | b=bloc               { $code = $b.code; }
    | ret=retour SEMI      { $code = $ret.code; }
    | call=appel_proc SEMI { $code = $call.code; }
;

retour returns [String code]
    : 'retourner' e=expr
    {
        if (!isLocal) throw new RuntimeException("Retour hors fonction");
       
        if (currentFuncReturnType.equals("RAT") && $e.type.equals("INT")) $code = $e.code + "PUSHI 1\n";
        else if (currentFuncReturnType.equals("INT") && $e.type.equals("RAT")) $code = $e.code + "POP\n";
        else $code = $e.code;

        int offsetRet = - (currentParamSize + 3);
        if (currentFuncReturnType.equals("RAT")) {
             $code += "STOREL " + offsetRet + "\n";      
             $code += "STOREL " + (offsetRet - 1) + "\n";
        } else {
             $code += "STOREL " + offsetRet + "\n";
        }
        $code += "RETURN\n";
    }
;

appel_proc returns [String code]
    : id=ID '(' args=arguments ')'
    {
       if (!funcTable.containsKey($id.text)) throw new RuntimeException("Fonction inconnue: " + $id.text);
       FuncSignature fs = funcTable.get($id.text);
       
       $code = "";
       if (fs.returnType.equals("RAT")) $code += "PUSHI 0\nPUSHI 0\n"; else $code += "PUSHI 0\n";
       
       if ($args.types.size() != fs.paramTypes.size()) throw new RuntimeException("Args incorrects");
       
       for(int i=0; i<fs.paramTypes.size(); i++) {
           String pt = fs.paramTypes.get(i);
           String at = $args.types.get(i);
           $code += $args.codeList.get(i);
           if(pt.equals("INT") && at.equals("RAT")) $code += "POP\n";
           else if(pt.equals("RAT") && at.equals("INT")) $code += "PUSHI 1\n";
       }
       
       $code += "CALL " + fs.label + "\n";
       
       for(String tArg : fs.paramTypes) {
           if (tArg.equals("RAT")) $code += "POP\nPOP\n"; else $code += "POP\n";
       }
       if (fs.returnType.equals("RAT")) $code += "POP\nPOP\n"; else $code += "POP\n";
    }
;

arguments returns [List<String> codeList, List<String> types]
    @init { $codeList = new ArrayList<>(); $types = new ArrayList<>(); }
    : (e1=expr { $codeList.add($e1.code); $types.add($e1.type); }
       (',' e2=expr { $codeList.add($e2.code); $types.add($e2.type); })* )?
;

bloc returns [String code]
    @init { $code = ""; } : '{' (s=stmt { $code += $s.code; })* '}';

affectation returns [String code]
    : id=ID '=' e=expr
    {
        String varType = getType($id.text);
        $code = $e.code;
        if (varType.equals("RAT")) {
            if ($e.type.equals("INT")) $code += "PUSHI 1\n";
            $code += getStoreInst($id.text, 1) + getStoreInst($id.text, 0);
        } else if (varType.equals("INT") && $e.type.equals("RAT")) {
            $code += "POP\n" + getStoreInst($id.text, 0);
        } else $code += getStoreInst($id.text, 0);
    }
    // AFFECTATION SIMPLE (1 Niveau)
    | id=ID '.' champ=ID '=' e=expr
    {
        String structType = getType($id.text);
        if (!structFields.containsKey(structType)) throw new RuntimeException($id.text + " n'est pas une structure");
       
        int offsetChamp = structFields.get(structType).get($champ.text);
        String fieldType = structFieldTypes.get(structType).get($champ.text);
       
        $code = $e.code;
        if (fieldType.equals("RAT") && $e.type.equals("INT")) $code += "PUSHI 1\n";
        else if (fieldType.equals("INT") && $e.type.equals("RAT")) $code += "POP\n";

        if (isLocal && localSymTable.containsKey($id.text)) {
            int base = localSymTable.get($id.text);
            if (fieldType.equals("RAT")) {
                 $code += "STOREL " + (base + offsetChamp + 1) + "\n";
                 $code += "STOREL " + (base + offsetChamp) + "\n";    
            } else {
                 $code += "STOREL " + (base + offsetChamp) + "\n";
            }
        } else {
             int base = symTable.get($id.text);
             if (fieldType.equals("RAT")) {
                 $code += "STOREG " + (base + offsetChamp + 1) + "\n";
                 $code += "STOREG " + (base + offsetChamp) + "\n";
            } else {
                 $code += "STOREG " + (base + offsetChamp) + "\n";
            }
        }
    }
    // AFFECTATION IMBRIQUEE (2 Niveaux: c.centre.x)
    | id=ID '.' c1=ID '.' c2=ID '=' e=expr
    {
        String t1 = getType($id.text);
        int off1 = structFields.get(t1).get($c1.text);
        String t2 = structFieldTypes.get(t1).get($c1.text);
       
        int off2 = structFields.get(t2).get($c2.text);
        String finalType = structFieldTypes.get(t2).get($c2.text);
       
        int totalOffset = off1 + off2;
       
        $code = $e.code;
        if (finalType.equals("RAT") && $e.type.equals("INT")) $code += "PUSHI 1\n";
        else if (finalType.equals("INT") && $e.type.equals("RAT")) $code += "POP\n";

        if (isLocal && localSymTable.containsKey($id.text)) {
            int base = localSymTable.get($id.text);
            if (finalType.equals("RAT")) {
                 $code += "STOREL " + (base + totalOffset + 1) + "\n";
                 $code += "STOREL " + (base + totalOffset) + "\n";
            } else {
                 $code += "STOREL " + (base + totalOffset) + "\n";
            }
        } else {
             int base = symTable.get($id.text);
             if (finalType.equals("RAT")) {
                 $code += "STOREG " + (base + totalOffset + 1) + "\n";
                 $code += "STOREG " + (base + totalOffset) + "\n";
            } else {
                 $code += "STOREG " + (base + totalOffset) + "\n";
            }
        }
    }
;

condition returns [String code]
    : cond=exprBool '?' stmtA=stmt ( ':' stmtB=stmt )?
    {
        String lElse = newLabel(); String lEnd = newLabel();
        $code = $cond.code + "JUMPF " + lElse + "\n" + $stmtA.code + "JUMP " + lEnd + "\n";
        $code += "LABEL " + lElse + "\n";
        if ($stmtB.ctx != null) $code += $stmtB.code;
        $code += "LABEL " + lEnd + "\n";
    }
;

loop returns [String code]
    : 'Pour' id=ID '=' deb=atomInt2 '..' fin=atomInt2 'Faire' instr=stmt
      {
        String lblLoop = newLabel(); String lblEnd = newLabel();
        if(!getType($id.text).equals("INT")) throw new RuntimeException("Index doit être ENTIER");
        $code = $deb.code + getStoreInst($id.text, 0);
        int limitAddr = currentAddr++;
        $code += $fin.code + "STOREG " + limitAddr + "\n";
        $code += "LABEL " + lblLoop + "\n" + $instr.code + getPushInst($id.text) + "PUSHG " + limitAddr + "\nNEQ\nJUMPF " + lblEnd + "\n";
        $code += getPushInst($id.text) + "PUSHI 1\nADD\n" + getStoreInst($id.text, 0) + "JUMP " + lblLoop + "\nLABEL " + lblEnd + "\n";
      }
    | 'repeter' instr=stmt 'jusque' cond=exprBool
    {
        String lblLoop = newLabel();
        $code = "LABEL " + lblLoop + "\n" + $instr.code + $cond.code + "JUMPF " + lblLoop + "\n";
    }
;

affiche returns [String code]
    : 'Afficher' '(' exprAff=expr ')' {
        $code = $exprAff.code;                      
         if($exprAff.type != null && $exprAff.type.equals("RAT")) $code += "STOREG 1\nSTOREG 0\nPUSHG 0\nWRITE\nPUSHG 1\nWRITE\n";
         else $code += "WRITE\n";
    }
;

expr returns [String code, String type]
    : { _input.LT(1).getType() == ID && isVar(_input.LT(1).getText()) && getType(_input.LT(1).getText()).equals("BOOL") }?
      b=exprBool { $code = $b.code; $type = $b.type; }
    | { _input.LT(1).getType() == TRUE_KW || _input.LT(1).getType() == FALSE_KW || _input.LT(1).getType() == NOT_KW }?
      b2=exprBool { $code = $b2.code; $type = $b2.type; }
    | { (_input.LT(1).getType() != ID) || (isVar(_input.LT(1).getText()) && getType(_input.LT(1).getText()).equals("INT")) || (getFuncType(_input.LT(1).getText()) != null && getFuncType(_input.LT(1).getText()).equals("INT")) }?
      c=atomInt2 { $code = $c.code; $type = $c.type; }
    | a=arith_exp { $code = $a.code; $type = "RAT"; }
;

arith_exp returns [String code,String type]
    : t1=term { $code = $t1.code; }
      (op=('+'|'-') t2=term {
        $code += $t2.code + "STOREL 3\nSTOREL 2\nSTOREL 1\nSTOREL 0\n";
        if($op.text.equals("+")) $code += "PUSHL 0\nPUSHL 3\nMUL\nPUSHL 1\nPUSHL 2\nMUL\nADD\nSTOREL 0\nPUSHL 1\nPUSHL 3\nMUL\nSTOREL 1\n";
        else $code += "PUSHL 0\nPUSHL 3\nMUL\nPUSHL 1\nPUSHL 2\nMUL\nSUB\nSTOREL 0\nPUSHL 1\nPUSHL 3\nMUL\nSTOREL 1\n";
        $code += "PUSHL 0\nPUSHL 1\n";
        $type = "RAT";
    })*
;

term returns [String code,String type]
    : f1=factor { $code = $f1.code; }
      (op=('*'|':') f2=factor {
        $code += $f2.code + "STOREL 3\nSTOREL 2\nSTOREL 1\nSTOREL 0\n";
        if($op.text.equals("*")) $code += "PUSHL 0\nPUSHL 2\nMUL\nPUSHL 1\nPUSHL 3\nMUL\nSTOREL 1\nSTOREL 0\n";
        else $code += "PUSHL 0\nPUSHL 3\nMUL\nPUSHL 1\nPUSHL 2\nMUL\nSTOREL 1\nSTOREL 0\n";
        $code += "PUSHL 0\nPUSHL 1\n";
        $type = "RAT";
    })*
;
factor returns [String code, String type]
    : id=ID { isVar($id.text) && (getType($id.text).equals("RAT") || getType($id.text).equals("INT")) }?
      {
        String name = $id.text;
        if(getType(name).equals("RAT")) {
             if (isLocal && localSymTable.containsKey(name)) { int addr = localSymTable.get(name); $code = "PUSHL " + addr + "\n" + "PUSHL " + (addr + 1) + "\n"; }
             else { int addr = symTable.get(name); $code = "PUSHG " + addr + "\n" + "PUSHG " + (addr + 1) + "\n"; }
        } else { $code = getPushInst(name) + "PUSHI 1\n"; }
        $type = "RAT";
      }
    | callId=ID '(' args=arguments ')'
      {
         if (!funcTable.containsKey($callId.text)) throw new RuntimeException("Fonction inconnue");
         FuncSignature fs = funcTable.get($callId.text);
         if (fs.returnType.equals("RAT")) $code = "PUSHI 0\nPUSHI 0\n"; else $code = "PUSHI 0\n";
         if ($args.types.size() != fs.paramTypes.size()) throw new RuntimeException("Nb args invalide");
         for(int i=0; i<fs.paramTypes.size(); i++) {
             $code += $args.codeList.get(i);
             if(fs.paramTypes.get(i).equals("INT") && $args.types.get(i).equals("RAT")) $code += "POP\n";
             else if(fs.paramTypes.get(i).equals("RAT") && $args.types.get(i).equals("INT")) $code += "PUSHI 1\n";
         }
         $code += "CALL " + fs.label + "\n";
         for(String tArg : fs.paramTypes) { if (tArg.equals("RAT")) $code += "POP\nPOP\n"; else $code += "POP\n"; }
         if (fs.returnType.equals("INT")) $code += "PUSHI 1\n";
         $type = "RAT";
      }
    |'lire' '(' ')' { $code = "READ\nREAD\n"; $type = "RAT"; }
    | a=atomInt { $code = $a.code + "PUSHI 1\n"; $type = "RAT"; }
    | r=RATIONAL { String[] parts = $r.text.split("/"); $code = "PUSHI " + parts[0] + "\nPUSHI " + parts[1] + "\n"; $type = "RAT"; }
    | '(' inner=arith_exp ')' { $code = $inner.code; $type = "RAT"; }
    | base=factor '**' exp=atomInt {
        String loop = newLabel(); String end = newLabel();
        $code = $base.code + "STOREG 1\nSTOREG 0\nPUSHI 1\nSTOREG 2\nPUSHI 1\nSTOREG 3\n" + $exp.code + "STOREG 4\nLABEL " + loop + "\nPUSHG 4\nJUMPF " + end + "\nPUSHG 2\nPUSHG 0\nMUL\nSTOREG 2\nPUSHG 3\nPUSHG 1\nMUL\nSTOREG 3\nPUSHG 4\nPUSHI 1\nSUB\nSTOREG 4\nJUMP " + loop + "\nLABEL " + end + "\nPUSHG 2\nPUSHG 3\n"; $type = "RAT";
    }
    // LECTURE CHAMP SIMPLE (p.x)
    | id=ID '.' champ=ID
    {
        String structType = getType($id.text);
        if (!structFields.containsKey(structType)) throw new RuntimeException("Pas une structure");
        int offsetChamp = structFields.get(structType).get($champ.text);
        String fieldType = structFieldTypes.get(structType).get($champ.text);
       
        if (isLocal && localSymTable.containsKey($id.text)) {
            int base = localSymTable.get($id.text);
            if (fieldType.equals("RAT")) { $code = "PUSHL " + (base + offsetChamp) + "\n" + "PUSHL " + (base + offsetChamp + 1) + "\n"; }
            else { $code = "PUSHL " + (base + offsetChamp) + "\n" + "PUSHI 1\n"; }
        } else {
             int base = symTable.get($id.text);
             if (fieldType.equals("RAT")) { $code = "PUSHG " + (base + offsetChamp) + "\n" + "PUSHG " + (base + offsetChamp + 1) + "\n"; }
             else { $code = "PUSHG " + (base + offsetChamp) + "\n" + "PUSHI 1\n"; }
        }
        $type = "RAT";
    }
    // LECTURE CHAMP IMBRIQUE (c.centre.x)
    | id=ID '.' c1=ID '.' c2=ID
    {
        String t1 = getType($id.text);
        int off1 = structFields.get(t1).get($c1.text);
        String t2 = structFieldTypes.get(t1).get($c1.text);
        int off2 = structFields.get(t2).get($c2.text);
        String finalType = structFieldTypes.get(t2).get($c2.text);
        int totalOffset = off1 + off2;

        if (isLocal && localSymTable.containsKey($id.text)) {
            int base = localSymTable.get($id.text);
            if (finalType.equals("RAT")) { $code = "PUSHL " + (base + totalOffset) + "\n" + "PUSHL " + (base + totalOffset + 1) + "\n"; }
            else { $code = "PUSHL " + (base + totalOffset) + "\n" + "PUSHI 1\n"; }
        } else {
             int base = symTable.get($id.text);
             if (finalType.equals("RAT")) { $code = "PUSHG " + (base + totalOffset) + "\n" + "PUSHG " + (base + totalOffset + 1) + "\n"; }
             else { $code = "PUSHG " + (base + totalOffset) + "\n" + "PUSHI 1\n"; }
        }
        $type = "RAT";
    }
   
    | 'sim' '(' e=arith_exp ')' { $code = "PUSHI 1\nPUSHI 1\n" + $e.code + "CALL function_simp\nPOP\nPOP\n"; $type = "RAT"; }
;

atomInt returns [String code,String type]
    :  b=BOOL { $code = "PUSHI " + $b.text + "\n"; $type = "INT"; }
    | 'lire' '(' ')' { $code = "READ\n"; $type = "INT"; }
    | callId=ID '(' args=arguments ')'
      {
         if (!funcTable.containsKey($callId.text)) throw new RuntimeException("Fonction inconnue");
         FuncSignature fs = funcTable.get($callId.text);
         if (fs.returnType.equals("RAT")) throw new RuntimeException("Fonction retourne RAT");
         $code = "PUSHI 0\n";
         if ($args.types.size() != fs.paramTypes.size()) throw new RuntimeException("Nb args invalide");
         for(int i=0; i<fs.paramTypes.size(); i++) {
             $code += $args.codeList.get(i);
             if(fs.paramTypes.get(i).equals("INT") && $args.types.get(i).equals("RAT")) $code += "POP\n";
             else if(fs.paramTypes.get(i).equals("RAT") && $args.types.get(i).equals("INT")) $code += "PUSHI 1\n";
         }
         $code += "CALL " + fs.label + "\n";
         for(String tArg : fs.paramTypes) { if (tArg.equals("RAT")) $code += "POP\nPOP\n"; else $code += "POP\n"; }
         $type = "INT";
      }
   
    // LECTURE CHAMP INT (Simple)
    | id=ID '.' champ=ID
    {
        String structType = getType($id.text);
        int offsetChamp = structFields.get(structType).get($champ.text);
        if (isLocal && localSymTable.containsKey($id.text)) $code = "PUSHL " + (localSymTable.get($id.text) + offsetChamp) + "\n";
        else $code = "PUSHG " + (symTable.get($id.text) + offsetChamp) + "\n";
        $type = "INT";
    }
    // LECTURE CHAMP INT (Imbrique)
    | id=ID '.' c1=ID '.' c2=ID
    {
        String t1 = getType($id.text);
        int off1 = structFields.get(t1).get($c1.text);
        String t2 = structFieldTypes.get(t1).get($c1.text);
        int off2 = structFields.get(t2).get($c2.text);
        int totalOffset = off1 + off2;
        if (isLocal && localSymTable.containsKey($id.text)) $code = "PUSHL " + (localSymTable.get($id.text) + totalOffset) + "\n";
        else $code = "PUSHG " + (symTable.get($id.text) + totalOffset) + "\n";
        $type = "INT";
    }

    | id=ID {
         if(!getType($id.text).equals("INT")) throw new RuntimeException("Doit être INT");
         $code = getPushInst($id.text); $type = "INT";
     }
    | '[' e=arith_exp ']' { $code = "PUSHI 0\n" + $e.code + "CALL function_proche\nPOP\nPOP\n"; $type = "INT"; }
;

atomInt2 returns [String code,String type]
   : b=BOOL { $code = "PUSHI " + $b.text + "\n"; $type = "INT";}
    | callId=ID '(' args=arguments ')' {
         if (!funcTable.containsKey($callId.text)) throw new RuntimeException("Fonction inconnue");
         FuncSignature fs = funcTable.get($callId.text);
         $code = "PUSHI 0\n";
         for(int i=0; i<fs.paramTypes.size(); i++) {
             $code += $args.codeList.get(i);
             if(fs.paramTypes.get(i).equals("INT") && $args.types.get(i).equals("RAT")) $code += "POP\n";
             else if(fs.paramTypes.get(i).equals("RAT") && $args.types.get(i).equals("INT")) $code += "PUSHI 1\n";
         }
         $code += "CALL " + fs.label + "\n";
         for(String tArg : fs.paramTypes) { if (tArg.equals("RAT")) $code += "POP\nPOP\n"; else $code += "POP\n"; }
         $type = "INT";
    }
   | id=ID { $code = getPushInst($id.text); $type = "INT"; }
    |  'pgcd' '(' x=atomInt2 ',' y=atomInt2 ')' { $code = "PUSHI 0\n" + $x.code + $y.code + "CALL function_pgcd\nPOP\nPOP\n"; $type = "INT"; }
    | 'ppcm' '(' x=atomInt2 ',' y=atomInt2 ')' { $code = "PUSHI 0\n" + $x.code + $y.code + "CALL function_ppcm\nPOP\nPOP\n"; $type = "INT"; }
    | '[' e=arith_exp ']' { $code = "PUSHI 0\n" + $e.code + "CALL function_proche\nPOP\nPOP\n"; $type = "INT"; }
    | 'num(' e=arith_exp ')' { $code = $e.code + "POP\n"; $type = "INT"; }
    | 'denum(' e=arith_exp ')' { $code = $e.code + "STOREG 1\nPOP\nPUSHG 1\n"; $type = "INT"; }
    // SUPPORT CHAMPS DANS ATOMINT2
    | id=ID '.' champ=ID {
        String structType = getType($id.text);
        int offsetChamp = structFields.get(structType).get($champ.text);
        if (isLocal && localSymTable.containsKey($id.text)) $code = "PUSHL " + (localSymTable.get($id.text) + offsetChamp) + "\n";
        else $code = "PUSHG " + (symTable.get($id.text) + offsetChamp) + "\n";
        $type = "INT";
    }
    | id=ID '.' c1=ID '.' c2=ID {
        String t1 = getType($id.text);
        int off1 = structFields.get(t1).get($c1.text);
        String t2 = structFieldTypes.get(t1).get($c1.text);
        int off2 = structFields.get(t2).get($c2.text);
        int totalOffset = off1 + off2;
        if (isLocal && localSymTable.containsKey($id.text)) $code = "PUSHL " + (localSymTable.get($id.text) + totalOffset) + "\n";
        else $code = "PUSHG " + (symTable.get($id.text) + totalOffset) + "\n";
        $type = "INT";
    }
;
   
exprComp returns [String code, String type]
    : left=arith_exp op=('<' | '<=' | '>' | '>=' | '==' | '<>') right=arith_exp {
        $code = $left.code + $right.code;
        $code += "STOREL 3\nSTOREL 2\nSTOREL 1\nSTOREL 0\n";
        $code += "PUSHL 0\nPUSHL 3\nMUL\n";
        $code += "PUSHL 1\nPUSHL 2\nMUL\n";
        if($op.text.equals("<")) $code += "INF\n";
        else if($op.text.equals("<=")) $code += "INFEQ\n";
        else if($op.text.equals(">")) $code += "SUP\n";
        else if($op.text.equals(">=")) $code += "SUPEQ\n";
        else if($op.text.equals("==")) $code += "EQUAL\n";
        else $code += "NEQ\n";
        $type = "BOOL";
    }
;

exprBool returns [String code, String type] : left=exprBoolTerm { $code = $left.code; $type = $left.type; } ( 'or' right=exprBoolTerm { $code += "DUP\nJUMPF L1\nJUMP L2\nLABEL L1\nPOP\n" + $right.code + "LABEL L2\n"; $type = "BOOL"; })*;
exprBoolTerm returns [String code, String type] : left=exprBoolFactor { $code = $left.code; $type = $left.type; } ( 'and' right=exprBoolFactor { $code += "DUP\nJUMPF L1\nPOP\n" + $right.code + "LABEL L1\n"; $type = "BOOL"; })*;
exprBoolFactor returns [String code, String type]
    : 'not' f=exprBoolFactor { $code = $f.code + "NOT\n"; $type = "BOOL"; }
    | '(' i=exprBool ')' { $code = $i.code; $type = "BOOL"; }
    | b=BOOL { $code = "PUSHI " + $b.text + "\n"; $type = "BOOL"; }
    | TRUE_KW { $code = "PUSHI 1\n"; $type = "BOOL"; }    
    | FALSE_KW { $code = "PUSHI 0\n"; $type = "BOOL"; }
    | c=exprComp { $code = $c.code; $type = "BOOL"; }
    | id=ID { getType($id.text).equals("BOOL") }? { $code = getPushInst($id.text); $type = "BOOL"; }
    | callId=ID '(' args=arguments ')' {
         if (!funcTable.containsKey($callId.text)) throw new RuntimeException("Fonction inconnue");
         FuncSignature fs = funcTable.get($callId.text);
         $code = "PUSHI 0\n";
         for(int i=0; i<fs.paramTypes.size(); i++) {
             $code += $args.codeList.get(i);
             if(fs.paramTypes.get(i).equals("INT") && $args.types.get(i).equals("RAT")) $code += "POP\n";
             else if(fs.paramTypes.get(i).equals("RAT") && $args.types.get(i).equals("INT")) $code += "PUSHI 1\n";
         }
         $code += "CALL " + fs.label + "\n";
         for(String tArg : fs.paramTypes) { if (tArg.equals("RAT")) $code += "POP\nPOP\n"; else $code += "POP\n"; }
         $type = "BOOL";
    }
    | 'lire' '(' ')' { $code = "READ\nPUSHI 0\nSUP\n"; $type = "BOOL"; }
;

TRUE_KW  : 'true';
FALSE_KW : 'false';
 NOT_KW : 'not';
BOOL : [0-9]+;
RATIONAL : [0-9]+ '/' [0-9]+;
SEMI : ';';
 ID : [a-zA-Z_] [a-zA-Z0-9_]* ;
COMMENT  : '//' ~[\r\n]* -> skip;
WS : [ \t\r\n]+ -> skip;