grammar Rationnel;

@header {
import java.util.List;
}

@members {
    int labnum = 0;
    String newLabel() { return "L" + (labnum++); } 
}

// POINT D'ENTRÉE
start returns [String code]
    @init { $code = "ALLOC 20\n"; 
           String FIN_X = newLabel();
    String FIN_Y = newLabel();
    String FIN_BOUCLE = newLabel();
    String Y_X = newLabel();
    String DEB_BOUCLE = newLabel();
    String function_pgcd = 
                        "LABEL function_pgcd\n" +
                        "PUSHL -3\n"+
                        "JUMPF " + FIN_X +"\n"+
                        "PUSHL -4\n"+
                        "JUMPF " + FIN_Y +"\n"+

                        "LABEL "+ DEB_BOUCLE + "\n"+
                        "PUSHL -3\n"+
                        "PUSHL -4\n"+
                        "NEQ\n"+
                        "JUMPF " + FIN_BOUCLE + "\n"+
                        "PUSHL -3\n"+
                        "PUSHL -4\n"+
                        "INF\n"+
                        "JUMPF " + Y_X + "\n"+
                        "PUSHL -4\n"+
                        "PUSHL -3\n"+
                        "SUB\n"+
                        "STOREL -4\n"+
                        "JUMP " + DEB_BOUCLE + "\n"+
                        "LABEL "+ Y_X + "\n"+
                        "PUSHL -3\n"+
                        "PUSHL -4\n"+
                        "SUB\n"+
                        "STOREL -3\n"+
                        "JUMP "+DEB_BOUCLE + "\n"+
                        "LABEL " + FIN_BOUCLE + "\n"+
                        "PUSHL -4\n"+
                        "STOREL -5\n"+
                        "RETURN\n"+

                        "LABEL " + FIN_X + "\n"+
                        "PUSHL -4\n"+
                        "STOREL -5\n"+
                        "RETURN\n"+

                        "LABEL " + FIN_Y + "\n"+
                        "PUSHL -3\n"+
                        "STOREL -5\n"+
                        "RETURN\n";

            String function_ppcm = 
                        "LABEL function_ppcm\n" +
                        "PUSHL -3\n"+
                        "PUSHL -4\n"+
                        "MUL\n"+
                        "PUSHI 1\n"+
                        "PUSHL -3\n"+
                        "PUSHL -4\n"+
                        "CALL function_pgcd\n" +
                        "POP\n"+
                        "POP\n"+
                        "DIV \n" +
                        "STOREL -5\n"+
                        "RETURN \n";

            String function_simp =
                        "LABEL function_simp\n" +
                        "PUSHI 1\n"+
                        "PUSHL -3\n"+
                        "PUSHL -4\n"+
                        "CALL function_pgcd\n"+
                        "POP\n"+
                        "POP\n"+
                        "PUSHL -3\n"+
                        "PUSHL 0\n"+
                        "DIV" + "\n"+
                        "PUSHL -4\n"+
                        "PUSHL 0\n"+
                        "DIV" + "\n"+
                        "STOREL -6\n"+
                        "STOREL -5\n"+
                        
                        "RETURN\n";
            
            String function_proche = 
                        "LABEL function_proche\n" +
                        "PUSHL -3\n"+
                        "PUSHI 2\n"+
                        "DIV\n"+
                        "STOREL -5\n"+

                        "PUSHL -4\n"+
                        "PUSHL -5\n"+
                        "ADD\n"+
                        "STOREL -5\n"+

                        "PUSHL -5\n"+
                        "PUSHL -3\n"+
                        "DIV\n"+
                        "STOREL -5\n" + 
                        "RETURN\n";

            $code += "JUMP Start\n"+
                      function_pgcd +
                      function_simp +
                      function_ppcm +
                      function_proche +
                      "LABEL Start\n";
    } 
    : stmts+=stmt* EOF { 
        for(StmtContext ctx : $stmts) {
            $code += ctx.code; 
        }
        $code += "HALT\n";            
        System.out.println($code); 
    }
;

// INSTRUCTIONS
stmt returns [String code]
    : affiche=afficher SEMI { $code = $affiche.code; } 
;

// AFFICHAGE
afficher returns [String code]
    : 'Afficher' '(' exprAff=expr ')' {
        $code = $exprAff.code;                      
        if($exprAff.type.equals("RAT")) { 
            // Si c'est un rationnel, on a [Num, Den] sur la pile
            $code += "STOREG 1\n"; // Den
            $code += "STOREG 0\n"; // Num          
            $code += "PUSHG 0\n"; 
            $code += "WRITE\n";
            $code += "PUSHG 1\n";
            $code += "WRITE\n"; 
        } else {
            // Si c'est un entier pur ou un booléen
            $code += "WRITE\n";
        }
    }
;

// EXPRESSIONS
expr returns [String code, String type]
    : b=exprBool { $code = $b.code; $type = $b.type; }
    | c=atomInt2 { $code = $c.code; $type = $c.type; }
    | a=arith_exp { $code = $a.code; $type = $a.type; }
;

// EXPR RATIONNELLE (ADD/SUB)
arith_exp returns [String code,String type]
    : t1=term { $code = $t1.code; $type = "RAT"; } 
      (op=('+'|'-') t2=term {
        $code += $t2.code;

        $code += "STOREG 3\nSTOREG 2\nSTOREG 1\nSTOREG 0\n";
        
        if($op.text.equals("+")){
            $code += "PUSHG 0\nPUSHG 3\nMUL\n";
            $code += "PUSHG 1\nPUSHG 2\nMUL\n";
            $code += "ADD\n";
            $code += "STOREG 0\n";
            $code += "PUSHG 1\nPUSHG 3\nMUL\n";
            $code += "STOREG 1\n";
        }else{
            $code += "PUSHG 0\nPUSHG 3\nMUL\n";
            $code += "PUSHG 1\nPUSHG 2\nMUL\n";
            $code += "SUB\n";
            $code += "STOREG 0\n";
            $code += "PUSHG 1\nPUSHG 3\nMUL\n";
            $code += "STOREG 1\n";
        }
        
        $code += "PUSHG 0\n";
        $code += "PUSHG 1\n";
    })*
;

// TERMES (MULT/DIV)
term returns [String code,String type]
    : f1=factor { $code = $f1.code;$type = "RAT"; } 
      (op=('*'|':') f2=factor {
        $code += $f2.code;
        $code += "STOREG 3\nSTOREG 2\nSTOREG 1\nSTOREG 0\n"; 
        
        if($op.text.equals("*")){
            $code += "PUSHG 0\n";
            $code += "PUSHG 2\n";
            $code += "MUL\n";
            $code += "PUSHG 1\n";
            $code += "PUSHG 3\n";
            $code += "MUL\n";
            $code += "STOREG 1\n";
            $code += "STOREG 0\n"; 
        }else{
            $code += "PUSHG 0\n";
            $code += "PUSHG 3\n";
            $code += "MUL\n";
            $code += "PUSHG 1\n";
            $code += "PUSHG 2\n";
            $code += "MUL\n";
            $code += "STOREG 1\n";
            $code += "STOREG 0\n";
        }
        
        $code += "PUSHG 0\n";
        $code += "PUSHG 1\n";
    })*
;

// FACTEURS
factor returns [String code, String type]
    : 'lire' '(' ')' { 
        $code = "READ\n";
        $code += "READ\n";
        $type = "RAT"; 
    }
    // C'est ici que l'entier (qu'il vienne de pgcd, num, ou un chiffre) devient un Rationnel
    | a=atomInt { 
        $code = $a.code;      
        $code += "PUSHI 1\n"; // Conversion implicite : Int -> Int/1
        $type = "RAT";
    }
    | r=RATIONAL { 
        String[] parts = $r.text.split("/");
        $code = "PUSHI " + parts[0] + "\n"; 
        $code += "PUSHI " + parts[1] + "\n"; 
        $type = "RAT";
      }
    | '(' inner=arith_exp ')' { $code = $inner.code; $type = "RAT"; }
    | base=factor '**' exp=atomInt2 {
        // [Code de la puissance inchangé]
        String loop = newLabel();
        String end = newLabel();
        $code = $base.code; 
        $code += "STOREG 1\nSTOREG 0\n";
        $code += "PUSHI 1\nSTOREG 2\n"; // res_num
        $code += "PUSHI 1\nSTOREG 3\n"; // res_den
        $code += $exp.code; 
        $code += "STOREG 4\n"; // exposant

        $code += "LABEL " + loop + "\n";
        $code += "PUSHG 4\nJUMPF " + end + "\n";
        
        // Calcul
        $code += "PUSHG 2\nPUSHG 0\nMUL\nSTOREG 2\n";
        $code += "PUSHG 3\nPUSHG 1\nMUL\nSTOREG 3\n";
        
        // Décrément
        $code += "PUSHG 4\nPUSHI 1\nSUB\nSTOREG 4\n";
        $code += "JUMP " + loop + "\n";
        $code += "LABEL " + end + "\n";

        $code += "PUSHG 2\n";
        $code += "PUSHG 3\n";
        $type = "RAT";
    }
    | 'sim' '(' e=arith_exp ')' {
        $code = "PUSHI 1\n" + "PUSHI 1\n" + $e.code + "CALL function_simp\n" + "POP\nPOP\n";    
        $type = "RAT";
    }
    
;

// ENTIERS (Retourne un seul int sur la pile)
atomInt returns [String code,String type]
    :  b=BOOL { 
        $code = "PUSHI " + $b.text + "\n";
        $type = "INT";
      }
    | 'lire' '(' ')' { 
        $code = "READ\n"; 
        $type = "INT";
    }
    | '[' e=arith_exp ']' {
         $code = "PUSHI 0\n" 
               + $e.code 
               + "CALL function_proche\n"
               + "POP\nPOP\n"; 
               $type = "INT";     
    }
;
atomInt2 returns [String code,String type]
 : b=BOOL { 
        $code = "PUSHI " + $b.text + "\n";
        $type = "INT";
      }
    | 'lire' '(' ')' { 
        $code = "READ\n"; 
        $type = "INT";
    }
    | 'pgcd' '(' x=atomInt2 ',' y=atomInt2 ')' {
         $code = "PUSHI 0\n" 
               + $x.code 
               + $y.code 
               + "CALL function_pgcd\n"
               + "POP\nPOP\n";      
               $type = "INT";
    }
    | 'ppcm' '(' x=atomInt2 ',' y=atomInt2 ')' {
         $code = "PUSHI 0\n"
               + $x.code
               + $y.code
               + "CALL function_ppcm\n"
               + "POP\nPOP\n";
               $type = "INT";
    }
    | '[' e=arith_exp ']' {
         $code = "PUSHI 0\n" 
               + $e.code 
               + "CALL function_proche\n"
               + "POP\nPOP\n";      
    }
    // NOUVEL EMPLACEMENT DE NUM ET DENUM
    | 'num(' e=arith_exp ')' {
         $code = $e.code + "POP\n"; // On garde le Num, on jette le Den. Résultat : Int
         $type = "INT";
    }
    | 'denum(' e=arith_exp ')' {
         $code = $e.code + "STOREG 1\nPOP\nPUSHG 1\n"; // On sauve Den, on jette Num, on récupère Den. Résultat : Int
         $type = "INT";
    }
;

// COMPARAISONS
exprComp returns [String code, String type]
    : left=arith_exp op=('<' | '<=' | '>' | '>=' | '==' | '<>') right=arith_exp {
        $code = $left.code + $right.code;
        $code += "STOREG 3\nSTOREG 2\nSTOREG 1\nSTOREG 0\n";
        $code += "PUSHG 0\nPUSHG 3\nMUL\n"; 
        $code += "PUSHG 1\nPUSHG 2\nMUL\n"; 
        
        if($op.text.equals("<")) $code += "INF\n";
        else if($op.text.equals("<=")) $code += "INFEQ\n";
        else if($op.text.equals(">")) $code += "SUP\n";
        else if($op.text.equals(">=")) $code += "SUPEQ\n";
        else if($op.text.equals("==")) $code += "EQUAL\n";
        else $code += "NEQ\n";
        
        $type = "BOOL";
    }
;

// EXPRESSIONS BOOLÉENNES
exprBool returns [String code, String type]
    : left=exprBoolTerm { $code = $left.code; $type = $left.type; } 
      ( 'or' right=exprBoolTerm {
        String L_EvalRight = newLabel(); 
        String L_End = newLabel();
        $code += "DUP\n";
        $code += "JUMPF " + L_EvalRight + "\n"; 
        $code += "JUMP " + L_End + "\n"; 
        $code += "LABEL " + L_EvalRight + "\n";
        $code += "POP\n"; 
        $code += $right.code; 
        $code += "LABEL " + L_End + "\n";
        $type = "BOOL";
    })*
;

exprBoolTerm returns [String code, String type]
    : left=exprBoolFactor { $code = $left.code; $type = $left.type; }
      ( 'and' right=exprBoolFactor {
        String L_EvalRight = newLabel();
        String L_End = newLabel();
        $code += "DUP\n";
        $code += "JUMPF " + L_End + "\n"; 
        $code += "POP\n"; 
        $code += $right.code; 
        $code += "LABEL " + L_End + "\n";
        $type = "BOOL";
    })*
;

exprBoolFactor returns [String code, String type]
    : 'not' factorBool=exprBoolFactor { $code = $factorBool.code + "NOT\n"; $type = "BOOL"; }
    | '(' innerBool=exprBool ')' { $code = $innerBool.code; $type = "BOOL"; }
    | b=BOOL { $code = "PUSHI " + $b.text + "\n"; $type = "BOOL"; }
    | c=exprComp { $code = $c.code; $type = "BOOL"; }
    | 'lire' '(' ')' {
        $code = "READ\n"; 
        $code += "PUSHI 0\nSUP\n"; 
        $type = "BOOL";
    }
;

// TOKENS
BOOL     : [0-9]+;
RATIONAL : [0-9]+ '/' [0-9]+;
SEMI     : ';';
WS       : [ \t\r\n]+ -> skip;