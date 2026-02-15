// HAMDOUCHE ABDALLAH SAMY , BACHTA YASSER
grammar Rationnel;

@header {
import java.util.List;
}

@members {
    int labnum = 0;     // labels uniques pour les sauts
    String newLabel() { return "L" + (labnum++); } 
}

// POINT D'ENTRÉE
start returns [String code]
    @init { $code = "ALLOC 20\n"; } 
    : stmts+=stmt* EOF { 
        /*J'ai une liste de toutes les instructions que j'ai lues ($stmts). Je vais prendre chaque instruction une par une (ctx). Je vais regarder la traduction en assembleur que cette instruction a calculée (ctx.code). Je vais coller cette traduction à la suite de mon grand fichier final ($code)*/
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
            // Le résultat est SUR LA PILE [Num, Den]. 
            // On doit le dépiler pour l'afficher.
            $code += "STOREG 1\n"; // Dépile le Dénominateur (sommet)
            $code += "STOREG 0\n"; // Dépile le Numérateur (dessous)         
            $code += "PUSHG 0\n"; // num
            $code += "WRITE\n";
            $code += "PUSHG 1\n";// denum
            $code += "WRITE\n"; 
        } else {
            $code += "WRITE\n";
        }
    }
;

// EXPRESSIONS
expr returns [String code, String type]
    // On tente d'abord de parser une expression booléenne (qui inclut les comparaisons et les bools simples)
    : b=exprBool { $code = $b.code; $type = $b.type; }
    | a=arith_exp { $code = $a.code; $type = "RAT"; }
;

// EXPR RATIONNELLE (ADD/SUB)
arith_exp returns [String code]
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

    })*
;

// TERMES (MULT/DIV)
term returns [String code]
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

    })*
;

// FACTEURS
factor returns [String code, String type]
    : 'lire' '(' ')' { 
        // On lit 2 entiers pour un rationnel
        $code = "READ\n";
        $code += "READ\n";
        $type = "RAT"; 
    }
    | a=atomInt { 
        // Cas 1 : Un entier simple (3 ou lire() entier)
        // On doit le convertir en Rationnel n/1
        $code = $a.code; // Exécute le code (vide pour INT, "READ" pour lire)
        
        // Si c'était un littéral (ex: 3), on doit le PUSHER. 
        // Si c'était lire(), il est déjà sur la pile.
        if($a.val != null && !$a.val.isEmpty()) {
             $code += "PUSHI " + $a.val + "\n"; 
        }
        
        $code += "PUSHI 1\n"; // On ajoute le dénominateur 1
        // Résultat pile : [n, 1] -> C'est un rationnel 
        $type = "RAT"; 
      }
    | RATIONAL { 
        String[] parts = $RATIONAL.text.split("/");
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
        if($exp.val != null && !$exp.val.isEmpty()) {
             $code += "PUSHI " + $exp.val + "# exposant\n"; 
        }
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
;

// Règle pour obtenir un entier simple (soit littéral, soit lu)
atomInt returns [String code, String val]
    :  BOOL { 
        // FIX: Allow BOOL tokens (0 or 1) to be treated as numbers
        $code = ""; 
        $val = $BOOL.text;
      }
    | 'lire' '(' ')' { 
        $code = "READ\n"; // On lit UN SEUL entier
        $val = ""; // Pas de valeur statique connue
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
    | BOOL { $code = "PUSHI " + $BOOL.text + "\n"; $type = "BOOL"; }
    | c=exprComp {
        $code = $c.code;
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
BOOL     : [0-9]+;
RATIONAL : [0-9]+ '/' [0-9]+;
SEMI     : ';';
WS       : [ \t\r\n]+ -> skip;