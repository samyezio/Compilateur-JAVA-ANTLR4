grammar Rationnel;

@header {
    import java.util.Map;
    import java.util.HashMap;
}

@members {
    int labnum = 0;
    
    // Adresse mémoire courante (20 pour laisser la place aux registres temp 0-19)
    int currentAddr = 20; 

    // UNE SEULE table des symboles (plus de pile/Stack)
    Map<String, Integer> symTable = new HashMap<>();
    Map<String, String> typeTable = new HashMap<>();

    String newLabel() { return "L" + (labnum++); }

    // Vérifie si une variable existe
    void checkVar(String id) {
        if (!symTable.containsKey(id)) 
            throw new RuntimeException("Erreur sémantique : Variable '" + id + "' non déclarée.");
    }

    // Récupère l'adresse (Directement dans la Map unique)
    int getAddr(String id) {
        checkVar(id);
        return symTable.get(id);
    }

    // Récupère le type
    String getType(String id) {
        checkVar(id);
        return typeTable.get(id);
    }

    // Enregistre une variable (Vérifie juste qu'elle n'existe pas déjà)
    void declareVar(String id, String type) {
        if (symTable.containsKey(id)) {
            throw new RuntimeException("Erreur sémantique : Variable '" + id + "' déjà déclarée.");
        }

        symTable.put(id, currentAddr);
        typeTable.put(id, type);

        // Allocation mémoire
        if (type.equals("RAT")) {
            currentAddr += 2;
        } else {
            currentAddr += 1;
        }
    }
}

// --- STRUCTURE DU PROGRAMME ---
// 1. Déclarations -> 2. Instructions
start returns [String code]
    @init { 
        $code = "ALLOC 200\n"; 
        
    String FIN_X = newLabel();
    String FIN_Y = newLabel();
    String FIN_BOUCLE = newLabel();
    String ETIQ = newLabel();
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
                        "JUMPF " + ETIQ + "\n"+
                        "PUSHL -4\n"+
                        "PUSHL -3\n"+
                        "SUB\n"+
                        "STOREL -4\n"+
                        "JUMP " + DEB_BOUCLE + "\n"+
                        "LABEL "+ ETIQ + "\n"+
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
    : (d=decl { $code += $d.code; })* // Phase 1 : Déclarations
      (s=stmt { $code += $s.code; })* // Phase 2 : Instructions
      EOF 
    { 
        $code += "HALT\n";            
        System.out.println($code); 
    }
;

// --- DÉCLARATION (Uniquement Globales) ---
decl returns [String code]
    @init { 
        $code = ""; 
        String myType = ""; 
    }
    : t=typeVar 
      {
         // On détermine le type chaîne (RAT, INT, BOOL)
         if ($t.text.equals("rationnel")) myType = "RAT";
         else if ($t.text.equals("entier")) myType = "INT";
         else myType = "BOOL";
      }
      // On passe ce type à decl_atom
      d1=decl_atom[myType] { $code += $d1.code; }
      
      // Idem pour les variables suivantes
      ( ',' d2=decl_atom[myType] { $code += $d2.code; } )* SEMI 
;
// Nouvelle sous-règle pour gérer UNE variable et son initialisation éventuelle
// On a renommé [String typeVar] en [String tVar] pour éviter le conflit
decl_atom [String tVar] returns [String code]
    @init { $code = ""; }
    : id=ID 
      {
          // A. On déclare la variable avec le type reçu (tVar)
          declareVar($id.text, $tVar);
          int addr = getAddr($id.text);
      }
      // B. Initialisation optionnelle
      ( '=' e=expr 
        {
            // Vérification : pas de Rationnel vers Entier
            if ($tVar.equals("INT") && $e.type != null && $e.type.equals("RAT")) {
                throw new RuntimeException("Erreur: Impossible d'affecter un Rationnel à l'entier " + $id.text);
            }

            $code = $e.code;

            // Conversion Entier -> Rationnel (x devient x/1)
            if ($tVar.equals("RAT") && $e.type != null && $e.type.equals("INT")) {
                $code += "PUSHI 1\n"; 
            }

            // Génération du stockage
            if ($tVar.equals("RAT")) {
                // Stockage [Den, Num] ou [Num, Den] selon votre logique mémoire
                $code += "STOREG " + (addr + 1) + "\n"; 
                $code += "STOREG " + addr + "\n";       
            } else {
                $code += "STOREG " + addr + "\n";
            }
        }
      )? 
;

typeVar : 'entier' | 'booleen' | 'rationnel';

// --- INSTRUCTIONS ---
stmt returns [String code]
    : a=affiche SEMI       { $code = $a.code; } 
    | aff=affectation SEMI { $code = $aff.code; }
    | c=condition          { $code = $c.code; }
    | l=loop               { $code = $l.code; }
    | b=bloc               { $code = $b.code; } 
;

// BLOCS
bloc returns [String code]
    @init { $code = ""; }
    : '{' (s=stmt { $code += $s.code; })* '}'
;

// AFFECTATION
affectation returns [String code]
    : id=ID '=' e=expr 
    {
        String name = $id.text;
        int addr = getAddr(name);       
        String varType = getType(name); 

        // On récupère le code de l'expression calculée
        $code = $e.code; 

        // CAS 1 : La variable est un RATIONNEL
        if (varType.equals("RAT")) {
            // Si l'expression calculée était par miracle un INT (rare), on ajoute /1
            if ($e.type != null && $e.type.equals("INT")) {
                $code += "PUSHI 1\n";
            }
            // On stocke [Num, Den]
            $code += "STOREG " + (addr + 1) + "\n"; // Den
            $code += "STOREG " + addr + "\n";       // Num
        } 
        
        // CAS 2 : La variable est un ENTIER mais on reçoit un RATIONNEL (ex: x = 10 qui est 10/1)
        else if (varType.equals("INT") && $e.type != null && $e.type.equals("RAT")) {
            // Sur la pile on a [Num, Den]. On veut juste Num.
            $code += "POP\n";                 // On supprime le dénominateur
            $code += "STOREG " + addr + "\n"; // On stocke le numérateur
        }

        // CAS 3 : Cas normal (Int=Int, Bool=Bool)
        else {
            $code += "STOREG " + addr + "\n";
        }
    }
;
// CONDITION (exprC ? A : S)
condition returns [String code]
    : cond=exprBool '?' stmtA=stmt 
      ( ':' stmtB=stmt )? 
    {
        String labelElse = newLabel();
        String labelEnd = newLabel();

        $code = $cond.code; 
        $code += "JUMPF " + labelElse + "\n"; 
        $code += $stmtA.code; 
        $code += "JUMP " + labelEnd + "\n"; 
        
        $code += "LABEL " + labelElse + "\n";
       if ($stmtB.ctx != null) {
            $code += $stmtB.code; 
        }
        $code += "LABEL " + labelEnd + "\n";
    }
;

// BOUCLES
loop returns [String code]
    : 'Pour' id=ID '=' deb=atomInt2 '..' fin=atomInt2 'Faire' instr=stmt
      {
        String lblLoop = newLabel();
        String lblEnd = newLabel();
        String idx = $id.text;
        int idxAddr = getAddr(idx);

        if(!getType(idx).equals("INT")) 
            throw new RuntimeException("Erreur: index de boucle doit être de type ENTIER");

        // --- 1. Initialisation ---
        $code = $deb.code;
        $code += "STOREG " + idxAddr + "\n";

        // --- 2. Stocker la limite dans une variable temporaire ---
        int limitAddr = currentAddr++;
        $code += $fin.code;
        $code += "STOREG " + limitAddr + "\n";

        // --- 3. Boucle ---
        $code += "LABEL " + lblLoop + "\n" +
                 
                 // Instructions du corps
                 $instr.code +
                 
                 // Test i != limite ?
                 "PUSHG " + idxAddr + "\n" +
                 "PUSHG " + limitAddr + "\n" +
                 "NEQ\n" +    // i != limite ?
                 "JUMPF " + lblEnd + "\n" +  // Si i == limite, on sort
                 
                 // Incrément i
                 "PUSHG " + idxAddr + "\n" +
                 "PUSHI 1\n" +
                 "ADD\n" +
                 "STOREG " + idxAddr + "\n" +
                 
                 // Retour début
                 "JUMP " + lblLoop + "\n" +
                 "LABEL " + lblEnd + "\n";
      }
    // Version "repeter ... jusque"
    | 'repeter' instr=stmt 'jusque' cond=exprBool
    {
        String lblLoop = newLabel();
        $code = "LABEL " + lblLoop + "\n" + 
                $instr.code + 
                $cond.code + 
                "JUMPF " + lblLoop + "\n";
    }
;

// AFFICHAGE
affiche returns [String code]
    : 'Afficher' '(' exprAff=expr ')' {
        $code = $exprAff.code;                      
         if($exprAff.type != null && $exprAff.type.equals("RAT")) {
            $code += "STOREG 1\nSTOREG 0\nPUSHG 0\nWRITE\nPUSHG 1\nWRITE\n";
        } else {
            $code += "WRITE\n";
        }
    }
;

// --- EXPRESSIONS (Les mêmes que précédemment) ---

// EXPRESSIONS
expr returns [String code, String type]
    // 1. Si c'est une variable (ID) et qu'elle est de type BOOL -> Force exprBool
    : { _input.LT(1).getType() == ID && getType(_input.LT(1).getText()).equals("BOOL") }? 
      b=exprBool { $code = $b.code; $type = $b.type; }

    // 2. Si ça commence par 'true', 'false' ou 'not' -> Force exprBool
    | { _input.LT(1).getType() == TRUE_KW || _input.LT(1).getType() == FALSE_KW || _input.LT(1).getType() == NOT_KW }?
      b2=exprBool { $code = $b2.code; $type = $b2.type; }
   | { _input.LT(1).getType() != ID || getType(_input.LT(1).getText()).equals("INT") }? 
      c=atomInt2 { $code = $c.code; $type = $c.type; }
    // 3. Sinon, on suppose que c'est des maths (Arithmétique)
    // (Si c'est une comparaison genre x < y, arith_exp échouera plus tard et on pourra ajouter un fallback si nécessaire, 
    // mais pour ce TP, x < y est géré dans exprBoolFactor qui est appelé par les structures de contrôle, pas directement par Afficher(x<y))
    | a=arith_exp { $code = $a.code; $type = "RAT"; } 
;

// EXPR RATIONNELLE (ADD/SUB)
arith_exp returns [String code,String type]
    : t1=term { $code = $t1.code; } // Initialisation avant la boucle
      (op=('+'|'-') t2=term {
        $code += $t2.code;

        // La pile contient [Num1, Den1, Num2, Den2]. On les range.
        $code += "STOREG 3\nSTOREG 2\nSTOREG 1\nSTOREG 0\n";
        
        if($op.text.equals("+")){
            $code += "PUSHG 0\n";
            $code += "PUSHG 3\n";
            $code += "MUL\n";
            $code += "PUSHG 1\n";
            $code += "PUSHG 2\n";
            $code += "MUL\n";
            $code += "ADD\n";
            $code += "STOREG 0\n";
            $code += "PUSHG 1\n";
            $code += "PUSHG 3\n";
            $code += "MUL\n";
            $code += "STOREG 1\n";
        }else{
            $code += "PUSHG 0\n";
            $code += "PUSHG 3\n";
            $code += "MUL\n";
            $code += "PUSHG 1\n";
            $code += "PUSHG 2\n";
            $code += "MUL\n";
            $code += "SUB\n";
            $code += "STOREG 0\n";
            $code += "PUSHG 1\n";
            $code += "PUSHG 3\n";
            $code += "MUL\n";
            $code += "STOREG 1\n";
        }
        
        $code += "PUSHG 0\n";
        $code += "PUSHG 1\n";

        $type = "RAT";

    })*
;

// TERMES (MULT/DIV)
term returns [String code,String type]
    : f1=factor { $code = $f1.code; } // Initialisation
      (op=('*'|':') f2=factor {
        $code += $f2.code;

        $code += "STOREG 3\nSTOREG 2\nSTOREG 1\nSTOREG 0\n"; 
        /* Si on ne mette pas les lignes STOREG 3...0 au début :

PUSHG 0 va lire la valeur initiale de la mémoire (qui est 0).

le calcul fera 0 * 0 + 0 * 0.

Si on mette pas les lignes PUSHG 0...1 à la fin :

Dans (3 + 4) * 5, l'addition 3+4 va calculer 7, le stocker en mémoire, puis vider la pile.

Quand la multiplication * 5 arrivera, elle cherchera le 7 sur la pile, mais la pile sera vide (ou contiendra juste le 5). Le programme plantera ou donnera un résultat faux.*/
        
        if($op.text.equals("*")){
            $code += "PUSHG 0\n";
            $code += "PUSHG 2\n";
            $code += "MUL\n";
            $code += "PUSHG 1\n";
            $code += "PUSHG 3\n";
            $code += "MUL\n";
            $code += "STOREG 1\n";
            $code += "STOREG 0\n"; // Optimisé: store directement
        }else{
            // Division (a/b : c/d) = (a*d) / (b*c)
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
        $type = "RAT";

    })*
;

// FACTEURS
factor returns [String code, String type]
    : id=ID { getType($id.text).equals("RAT") || getType($id.text).equals("INT") }? 
      {
        String name = $id.text; // Utilise $id.text au lieu de $ID.text
        int addr = getAddr(name);
        String t = getType(name);
        
        if(t.equals("RAT")) {
             $code = "PUSHG " + addr + "\n" + "PUSHG " + (addr + 1) + "\n";
        } else {
             // C'est un INT, on le convertit
             $code = "PUSHG " + addr + "\n" + "PUSHI 1\n"; 
        }
        $type = "RAT";
      }
    |'lire' '(' ')' { 
        // On lit 2 entiers pour un rationnel
        $code = "READ\n";
        $code += "READ\n";
        $type = "RAT"; 
    }
    | a=atomInt { 
        // atomInt a DÉJÀ généré le code pour mettre l'entier sur la pile (PUSHI 5, READ, ou CALL...)
        // On récupère juste ce code.
        $code = $a.code;     
        
        // On ajoute le dénominateur 1 pour en faire un Rationnel compatible
        $code += "PUSHI 1\n"; 
        
        $type = "RAT";
    }
    | r=RATIONAL { 
        String[] parts = $r.text.split("/");
        $code = "PUSHI " + parts[0] + "\n"; // Num
        $code += "PUSHI " + parts[1] + "\n"; // Denum
        // Résultat pile : [n, d] -> PAS DE STOREG ! et 'addition (dans arith_exp) fait les STOREG maintenant pour calculer.
        $type = "RAT";
      }
    | '(' inner=arith_exp ')' { $code = $inner.code; $type = "RAT"; }
    | base=factor '**' exp=atomInt {
       // puissance d'un rationnel a/b ** n
        String loop = newLabel();
        String end = newLabel();
        $code = $base.code;                      // charger le rationnel de base

        //  Sauvegarde Base en Mémoire (CRITIQUE)
        $code += "STOREG 1\n"; // Sauve Den
        $code += "STOREG 0\n"; // Sauve Num
     
        // Init Résultat (1/1)
        $code += "PUSHI 1  # résultat_num initial\n";
        $code += "STOREG 2\n";
        $code += "PUSHI 1  # résultat_den initial\n";
        $code += "STOREG 3\n";

        // L'Exposant
        $code += $exp.code; // "READ" ou rien
        $code += "STOREG 4\n";

        $code += "LABEL " + loop + "  # début boucle\n";
        $code += "PUSHG 4  # lire exposant\n";
        $code += "JUMPF " + end + "  # si exposant=0, fin boucle\n";

        $code += "PUSHG 2  # résultat_num\n";
        $code += "PUSHG 0  # base_num\n";
        $code += "MUL\n";
        $code += "STOREG 2  # mettre à jour résultat_num\n"; //Num = Num * BaseNum

        $code += "PUSHG 3  # résultat_den\n";
        $code += "PUSHG 1  # base_den\n";
        $code += "MUL\n";
        $code += "STOREG 3  # mettre à jour résultat_den\n";//Den = Den * BaseDen

        $code += "PUSHG 4  # exposant\n";
        $code += "PUSHI 1\n";
        $code += "SUB\n";
        $code += "STOREG 4  # décrémenter exposant\n";

        $code += "JUMP " + loop + "  # boucle suivante\n";
        $code += "LABEL " + end + "  # fin boucle\n";

    // On met le résultat SUR LA PILE pour la suite du programme
    // PAS DE STOREG ICI
        $code += "PUSHG 2  # résultat_num\n";
        $code += "PUSHG 3  # résultat_den\n";

        $type = "RAT";
    }
    // Simplification (Renvoie un Rationnel, donc reste dans factor)
    | 'sim' '(' e=arith_exp ')' {
        $code = "PUSHI 1\n"      // Slot retour Num
              + "PUSHI 1\n"      // Slot retour Den
              + $e.code          // Rationnel à simplifier
              + "CALL function_simp\n"
              + "POP\nPOP\n";    // Nettoie args
        $type = "RAT";
    }
;

// Règle pour obtenir un entier simple (soit littéral, soit lu)
atomInt returns [String code,String type]
    :  b=BOOL { 
        $code = "PUSHI " + $b.text + "\n";
        $type = "INT";
      }
    | 'lire' '(' ')' { 
        $code = "READ\n"; // On lit UN SEUL entier
        $type = "INT";
      
    }
     // Filtre : Uniquement si c'est un INT
    | id=ID     { 
         if(!getType($id.text).equals("INT")) 
             throw new RuntimeException("Variable " + $id.text + " doit être INT");
         $code = "PUSHG " + getAddr($id.text) + "\n"; 
     }
    // [...] Proche : prend un rationnel, renvoie un entier
    | '[' e=arith_exp ']' {
         $code = "PUSHI 0\n"        // Slot résultat
               + $e.code            // Calcule l'expression rationnelle (Num, Den)
               + "CALL function_proche\n"
               + "POP\nPOP\n";      // Nettoie Num et Den
    }

;

atomInt2 returns [String code,String type]
   : b=BOOL     { $code = "PUSHI " + $b.text + "\n"; $type = "INT";}
   | id=ID     { 
         if(!getType($id.text).equals("INT")) 
             throw new RuntimeException("Variable " + $id.text + " doit être INT");
         $code = "PUSHG " + getAddr($id.text) + "\n"; 
     }
    |  'pgcd' '(' x=atomInt2 ',' y=atomInt2 ')' {
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
               $type = "INT"; 
    }
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

        // --- CE QU'IL MANQUAIT : VIDER LA PILE DANS LA MÉMOIRE ---
        $code += "STOREG 3\nSTOREG 2\nSTOREG 1\nSTOREG 0\n";
        
        // Comparaison produits en croix : a/b op c/d <=> a*d op c*b
        $code += "PUSHG 0\nPUSHG 3\nMUL\n"; // a*d
        $code += "PUSHG 1\nPUSHG 2\nMUL\n"; // c*b
        
        if($op.text.equals("<")) $code += "INF\n";
        else if($op.text.equals("<=")) $code += "INFEQ\n";
        else if($op.text.equals(">")) $code += "SUP\n";
        else if($op.text.equals(">=")) $code += "SUPEQ\n";
        else if($op.text.equals("==")) $code += "EQUAL\n";
        else $code += "NEQ\n";
        
        $type = "BOOL";
    }
;

// EXPRESSIONS BOOLÉENNES (OR)
exprBool returns [String code, String type]
    : left=exprBoolTerm { $code = $left.code; $type = $left.type; } 
      ( 'or' right=exprBoolTerm {
        String L_EvalRight = newLabel(); 
        String L_End = newLabel();
        
        // Lazy Eval OR : Si Left est VRAI (1), on ne fait pas Right
        // Pile contient Resultat Left.
        $code += "DUP\n";              // [resL, resL]
        $code += "JUMPF " + L_EvalRight + "\n"; // Si resL == 0 (Faux), on va evaluer droite
        $code += "JUMP " + L_End + "\n";        // Si resL == 1 (Vrai), on garde le 1 et on finit
        
        $code += "LABEL " + L_EvalRight + "\n";
        $code += "POP\n";              // On vire le 0 (Faux) de Left
        $code += $right.code;          // On évalue Right
        
        $code += "LABEL " + L_End + "\n";
        $type = "BOOL";
    })*
;

// EXPRESSIONS BOOLÉENNES (AND)
exprBoolTerm returns [String code, String type]
    : left=exprBoolFactor { $code = $left.code; $type = $left.type; }
      ( 'and' right=exprBoolFactor {
        String L_EvalRight = newLabel();
        String L_End = newLabel();
        
        // Lazy Eval AND : Si Left est FAUX (0), on ne fait pas Right
        $code += "DUP\n";
        $code += "JUMPF " + L_End + "\n"; // Si 0, on garde le 0 et on saute à la fin
        $code += "POP\n";                 // Si 1, on vire le 1
        $code += $right.code;             // Et on évalue Right (le résultat sera celui de Right)
        
        $code += "LABEL " + L_End + "\n";
        $type = "BOOL";
    })*
;

exprBoolFactor returns [String code, String type]
    : 'not' factorBool=exprBoolFactor { $code = $factorBool.code + "NOT\n"; $type = "BOOL"; }
    | '(' innerBool=exprBool ')' { $code = $innerBool.code; $type = "BOOL"; }
    | b=BOOL { $code = "PUSHI " + $b.text + "\n"; $type = "BOOL"; }
    | TRUE_KW { $code = "PUSHI 1\n"; $type = "BOOL"; }   
    | FALSE_KW { $code = "PUSHI 0\n"; $type = "BOOL"; }
    | c=exprComp {
        $code = $c.code;
        $type = "BOOL";
    }
    | id=ID { getType($id.text).equals("BOOL") }? 
      {
        $code = "PUSHG " + getAddr($id.text) + "\n";
        $type = "BOOL";
      }
    // 3. Lecture d'un Booléen (Spécifique : 1 entier qui devient 0 ou 1)
    | 'lire' '(' ')' {
        String lblVrai = newLabel();
        String lblFin = newLabel();
        $code = "READ\n";              // Lit un entier
        // Normalisation: Si > 0 alors 1, sinon 0 (Optionnel mais propre)
        $code += "PUSHI 0\nSUP\n";     // Vérifie si lu > 0. Résultat 1 ou 0.
        $type = "BOOL";
    }
;

// TOKENS
TRUE_KW  : 'true'; 
FALSE_KW : 'false';  
NOT_KW   : 'not';
BOOL     : [0-9]+;
RATIONAL : [0-9]+ '/' [0-9]+;
SEMI     : ';';
ID       : [a-zA-Z_] [a-zA-Z0-9_]* ;
WS       : [ \t\r\n]+ -> skip;