

grammar Expr_Calculette;

@header {
    import java.util.*;
}

@members {
    // TABLE DE SYMBOLES/*4.1.2*/
    // --- MODIFICATION 4.3 : Gestion des Blocs (Piles) ---

    // memory stocke la valeur de chaque variable

   /* static Map<String, Object> memory = new HashMap<>();*/
      static List<Map<String, Object>> memoryStack = new ArrayList<>();

    // types stocke le type de chaque variable : "int" ou "bool"

    /*static Map<String, String> types = new HashMap<>();*/
      static List<Map<String, String>> typeStack = new ArrayList<>();

      // Initialisation statique
    static {
        memoryStack.add(new HashMap<>());
        typeStack.add(new HashMap<>());
    }

    // Créer un scanner pour la lecture clavier
    static java.util.Scanner sc = new java.util.Scanner(System.in);

    // --- METHODES DE SCOPE ---

    void pushScope() {
        memoryStack.add(new HashMap<>());
        typeStack.add(new HashMap<>());
    }

    void popScope() {
        if (memoryStack.size() > 1) {
            memoryStack.remove(memoryStack.size() - 1);
            typeStack.remove(typeStack.size() - 1);
        }
    }

    // Chercher le type (Vérifie si déclaré)
    String getType(String var) {
        for (int i = typeStack.size() - 1; i >= 0; i--) {
            if (typeStack.get(i).containsKey(var)) {
                return typeStack.get(i).get(var);
            }
        }
        return null; // Pas trouvé
    }

    Object getValue(String var) {
        // 1. On cherche d'abord DANS QUEL SCOPE la variable est déclarée
        int scopeIndex = -1;
        for (int i = typeStack.size() - 1; i >= 0; i--) {
            if (typeStack.get(i).containsKey(var)) {
                scopeIndex = i;
                break;
            }
        }

        if (scopeIndex == -1) {
            throw new RuntimeException("Variable non déclarée : " + var);
        }

        // 2. On vérifie si elle est initialisée dans ce scope précis
        if (memoryStack.get(scopeIndex).containsKey(var)) {
            return memoryStack.get(scopeIndex).get(var);
        } else {
            throw new RuntimeException("Variable utilisée avant affectation : " + var);
        }
    }

        // Modifier une variable (cherche où elle est déclarée pour l'initialiser au bon endroit)
    void setValue(String var, Object val) {
        // On cherche le scope de déclaration
        for (int i = typeStack.size() - 1; i >= 0; i--) {
            if (typeStack.get(i).containsKey(var)) {
                // On met à jour (ou on initialise) la mémoire à cet étage là
                memoryStack.get(i).put(var, val);
                return;
            }
        }
        throw new RuntimeException("Variable non déclarée (set) : " + var);
    }

    // Déclarer une variable (UNIQUEMENT dans types, PAS dans memory)
    void declareVar(String var, String type) {
        Map<String, String> currentTypes = typeStack.get(typeStack.size() - 1);
        
        if (currentTypes.containsKey(var)) {
            throw new RuntimeException("Variable déjà déclarée dans ce bloc : " + var);
        }
        currentTypes.put(var, type);
        
        // IMPORTANT : On ne met RIEN dans memory ici.
        // Cela garantit que getValue lancera l'erreur si on l'utilise tout de suite.
    }

    // --- FIN METHODES ---

    // Convertit un Object en booléen
    boolean asBool(Object o){
        if (o instanceof Boolean) 
            return ((Boolean)o);

        if (o instanceof Integer)
            return ((Integer)o) != 0;

        throw new RuntimeException("Expected boolean, got: " + o);
    }

    // Convertit un Object en entier
    int asInt(Object o){
        if (o instanceof Integer) 
            return ((Integer)o);

        throw new RuntimeException("Expected integer, got boolean");
    }
}


prog 
    : (stat)+ EOF
    ;


stat
    : decl (';' | NEWLINE) /*4.1.1*/
    | affect (';' | NEWLINE) /*4.1.2*/
    |block (';' | NEWLINE) /*4.3*/
    | e=expr (';' | NEWLINE) 
      { System.out.println($e.value); }
    | af'('e=expr')'{System.out.println($e.value);}
    | NEWLINE
    ;

/*4.3 Bloc*/
block
    : '{' 
      { pushScope(); }
      (stat)* '}' 
      { popScope(); }
    ;

expr returns [Object value]
    : e1=expr '<' e2=expr
      {   //4.1.4
          if (!($e1.value instanceof Integer) || !($e2.value instanceof Integer))
              throw new RuntimeException("'<' nécessite deux entiers");

          $value = asInt($e1.value) < asInt($e2.value);
      }

    | e1=expr '>' e2=expr
      {   //4.1.4
          if (!($e1.value instanceof Integer) || !($e2.value instanceof Integer))
              throw new RuntimeException("'>' nécessite deux entiers");

          $value = asInt($e1.value) > asInt($e2.value);
      }

    | e1=expr '<=' e2=expr
      {   //4.1.4
          if (!($e1.value instanceof Integer) || !($e2.value instanceof Integer))
              throw new RuntimeException("'<=' nécessite deux entiers");

          $value = asInt($e1.value) <= asInt($e2.value);
      }

    | e1=expr '>=' e2=expr
      {   //4.1.4
          if (!($e1.value instanceof Integer) || !($e2.value instanceof Integer))
              throw new RuntimeException("'>=' nécessite deux entiers");

          $value = asInt($e1.value) >= asInt($e2.value);
      }

    | e1=expr '==' e2=expr
      {
          // Comparaison possible sur int ou bool
          $value = $e1.value.equals($e2.value);
      }

    | e1=expr '<>' e2=expr
      {
          $value = !$e1.value.equals($e2.value);
      }

    | 'not' b1=exprb
      {   //4.1.4
          if (!($b1.value instanceof Boolean))
              throw new RuntimeException("'not' nécessite un booléen");

          $value = !asBool($e1.value);
      }

    | b1=exprb 'and' b2=exprb
      {   //4.1.4 
          if (!($b1.value instanceof Boolean) || !($b2.value instanceof Boolean))
              throw new RuntimeException("'and' nécessite deux booléens");

          $value = asBool($b1.value) && asBool($b2.value);
      }

    | b1=exprb 'or' b2=exprb
      {   //4.1.4
          if (!($b1.value instanceof Boolean) || !($b2.value instanceof Boolean))
              throw new RuntimeException("'or' nécessite deux booléens");

          $value = asBool($b1.value) || asBool($b2.value);
      }

    | t=term
      {
          $value = $t.value;
      }
    ;

exprb returns [Object value] :
    'true'                   
        { $value = true; }

    | 'false'                  
        { $value = false; }

    | '(' e=exprb ')'           
        { $value = $e.value; }
    
    | ID /*4.1.3*/
        {
            String var = $ID.text;

            //erreur non declare
            if (getType(var) == null)
               throw new RuntimeException("Variable non déclarée : " + var);

            //toute variable doit avoir une valeur avant l'utilisation dans une expression
            // getValue() va maintenant lancer l'exception si pas initialisé
            $value = getValue(var); 
        };
 

term returns [Object value]
    : t1=term '+' f=factor
      {   //4.1.4
          if (!($t1.value instanceof Integer) || !($f.value instanceof Integer))
              throw new RuntimeException("Addition impossible : opérandes non entières");

          $value = asInt($t1.value) + asInt($f.value);
      }

    | t1=term '-' f=factor
      {   //4.1.4
          if (!($t1.value instanceof Integer) || !($f.value instanceof Integer))
              throw new RuntimeException("Soustraction impossible : opérandes non entières");

          $value = asInt($t1.value) - asInt($f.value);
      }

    | f=factor
      {
          $value = $f.value;
      }
    ;



factor returns [Object value]
    : f1=factor '*' f2=atom    
        {   
            //4.1.4
            if (!($f1.value instanceof Integer) || !($f2.value instanceof Integer))
               throw new RuntimeException("Multiplication impossible : opérandes non entières");

            $value = asInt($f1.value) * asInt($f2.value); 
        }

    | f1=factor '/' f2=atom    
        {    
            //4.1.4
            if (!($f1.value instanceof Integer) || !($f2.value instanceof Integer))
              throw new RuntimeException("Division impossible : opérandes non entières");

             $value = asInt($f1.value) / asInt($f2.value); 
        }

    | a=atom                   
        { $value = $a.value; }
    ;


atom returns [Object value]
    : '-' a=atom
        { // Vérif : on doit avoir un entier 4.1.4
          if (!($a.value instanceof Integer))
              throw new RuntimeException("L'opérateur unaire '-' ne s'applique qu'aux entiers");

          $value = -asInt($a.value); }

    | INT                      
        { $value = Integer.parseInt($INT.text); }

    | '(' e=expr ')'           
        { $value = $e.value; }
    
    | ID /*4.1.3*/
        {
            String var = $ID.text;

            //erreur non declare
            if (getType(var) == null)
               throw new RuntimeException("Variable non déclarée : " + var);

            //toute variable doit avoir une valeur avant l'utilisation dans une expression
            // getValue() va maintenant lancer l'exception si pas initialisé
            $value = getValue(var); 
        }
    | '++' ID {
          //4.1.5
          String var = $ID.text;

            //erreur non declare
            if (getType(var) == null)
               throw new RuntimeException("Variable non déclarée : " + var);

            //4.1.4
            if (!getType(var).equals("int"))
                throw new RuntimeException("++ uniquement sur une variable int");
            
            int old = (int) getValue(var); // getValue lance erreur si pas init
            setValue(var, old + 1);
            $value = old;
    }
    |  ID '++'{
            //4.1.5
             String var = $ID.text;
            //erreur non declare

            if (getType(var) == null)
               throw new RuntimeException("Variable non déclarée : " + var);

            //toute variable doit avoir une valeur avant l'utilisation dans une expression

            //4.1.4
           if (!getType(var).equals("int"))
                throw new RuntimeException("++ uniquement sur une variable int");
            
            int old = (int) getValue(var); // getValue lance erreur si pas init
            setValue(var, old + 1);
            $value = old + 1;

    }
    | '--' ID {
           //4.1.5
           String var = $ID.text;
           //erreur non declare

            if (getType(var) == null)
               throw new RuntimeException("Variable non déclarée : " + var);

            //4.1.4
            if (!getType(var).equals("int"))
                throw new RuntimeException("-- uniquement sur une variable int");
            
            int old = (int) getValue(var); // getValue lance erreur si pas init
            setValue(var, old - 1);
            $value = old;
    }
    |  ID '--' {
          //4.1.5
           String var = $ID.text;
           //erreur non declare

            if (getType(var) == null)
               throw new RuntimeException("Variable non déclarée : " + var);

            //4.1.4
            if (!getType(var).equals("int"))
                throw new RuntimeException("-- uniquement sur une variable int");
            
            int old = (int) getValue(var); // getValue lance erreur si pas init
            setValue(var, old - 1);
            $value = old - 1;
    }
    | 'lire' /*4.2*/
          {
          System.out.print("Entrer une valeur : ");
        
           if (sc.hasNextLine()) {
              String input = sc.nextLine().trim();
              
              if (input.equalsIgnoreCase("true")) $value = true;
              else if (input.equalsIgnoreCase("false")) $value = false;
              else {
                  try {
                      $value = Integer.parseInt(input);
                  } catch (NumberFormatException e) {
                      throw new RuntimeException("Valeur invalide : " + input);
                  }
              }
          } else {
              throw new RuntimeException("Aucune entrée trouvée (Flux fermé)");
          }
      }
      
    ;
/*4.1.1 ,.2*/ 
decl
    : t=type ids+=ID (',' ids+=ID)*
      {
        // Pour tous les identifiants 
        for (Token tok : $ids) {
            String v = tok.getText();

        //erreur declare
           declareVar(v, $t.text);
        }
      }
    ;

affect
    : ID '=' expr
      {
        String var = $ID.text;
        String typeVar = getType(var);
        //erreur non declare
        if (typeVar == null)
            throw new RuntimeException("Variable non déclarée : " + var);

        Object val = $expr.value;

        // erreur vérification typage
        if (typeVar.equals("int") && !(val instanceof Integer))
            throw new RuntimeException("Type incorrect : " + var + " attend un entier");

        if (typeVar.equals("bool") && !(val instanceof Boolean))
            throw new RuntimeException("Type incorrect : " + var + " attend un booléen");

        setValue(var, val);
      }
    | ID '=' exprb
      {
        String var = $ID.text;
        String typeVar = getType(var);
        //erreur non declare
        if (typeVar == null)
            throw new RuntimeException("Variable non déclarée : " + var);

        Object val = $exprb.value;

        // erreur vérification typage
        if (typeVar.equals("int") && !(val instanceof Integer))
            throw new RuntimeException("Type incorrect : " + var + " attend un entier");

        if (typeVar.equals("bool") && !(val instanceof Boolean))
            throw new RuntimeException("Type incorrect : " + var + " attend un booléen");

        setValue(var, val);
      }
    ;


type : 'int' | 'bool' ;

/* TOKENS */
ID : [A-Za-z_][A-Za-z0-9_]*;
INT : [0-9]+ ;
NEWLINE : '\r'? '\n' ;
WS : [ \t]+ -> skip ;
