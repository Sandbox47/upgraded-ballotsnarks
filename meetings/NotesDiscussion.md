# Notes from 11.03.2025 (see UniMail)
- S. 18 (unten): Ich würde den Choice Space nicht als Teil der Instance sehen. Für mich wäre das eher ein Teil der Definition der Relation die der entsprechende ZKP beweist - so liest es sich auch in deiner Definition 2.5.4.
    - Ja, das kann ich auf jeden Fall machen. (Ich wollte es bevor ich es formalisiere noch möglichst einfach halten ;-)) 
    Wie würde ich das dann visualisieren? (Was muss ich an Figure 2.6 ändern, damit nach wie vor klar ist, dass der Choice Space in der Definition des Proving Algorithmus verwendet wird. (Soll ich dann eventuell $Prove(C)$) machen?)

- S.19: Was meinst du mit "assume [...] that the public bulletin board is available"? (Ich sehe, das wird später in einer Fußnote erklärt, die würde aber ggf. schon hier Sinn machen.)
    - Ja, das stimmt, ich habe die Fußnote leicht geändert und schon am Anfang angeführt.

- S.19: Ich bin mir nicht sicher ob ich die Choice Space-Definition verstehe.
    - Was genau ist hier das Problem? Liegt das an den natural numbers $\mathbb{N}$?
    - Ich habe die Definition jetzt leicht geändert und allgemein auf einem körper $\mathbb{F}$ basiert.

- S.19: Definition 2.5.3 ist sehr informal. Das ist an der Stelle erstmal nicht schlimm - ich wundere mich nur, wo das in dieser Form in [Gro16] steht, das du ja hierfür zitierst.
    - Ich havbe mich an den "Non-interactive zero-knowledge arguments of knowledge" orientiert mit folgenden Änderungen:
        1. Den Algorithmus $\text{Sim}$ habe ich weggelassen. Der ist doch nicht unbedingt nötig, oder?
        1. Die Relation $R$ habe ich nicht jedem Algorithmus ($\text{Setup, Prove, Vfy}$) übergeben, sondern als Argument des gesamtsystems aufgefasst.
        1. Für die Definition von Relationen habe ich mich am MoomMathManual orientiert (Section 6.1.2). Ich habe eine entsprechend e Zitierung ergänzt.

- S.21:Du hast recht, copying Attacken werden an dieser Stelle noch nicht verhindert. Hierzu könnte man beispielsweise für alle Ballots die mehrfach auf dem Bulletin Board auftauchen nur den ersten solchen Ballot zählen und die übrigen ignorieren. Da die Verschlüsselung und ZKPs randomisiert sind, würden wir damit nur mit vernachlässigbar kleiner Wahrscheinlichkeit ehrlich generierte Ballots entfernen. Man kann dann noch über re-randomization Attacks nachdenken, die aber genau durch die Proof-of-Knowledge Eigenschaft adressiert werden (ggf. müsste man noch über malleability von ZKPs nachdenken, aber das lassen wir jetzt mal außen vor). Details hierzu findest du in Section II A und B aus dem Paper über Replay Attacks, das du zitierst. Ich sehe gerade aber noch nicht, wie dein Vorschlag mit der Voter ID in der Instance des ZKPs funktioniert. Welche Relation würden wir dann beweisen?
    - Wenn ich die ID von einem voter in den ZKP einschließe, dann kann ich beweisen, dass genau dieser voter die Stimme abgegeben hat. (Das ist aber problematisch, weil ich dann einen eigenen Circuit für jeden voter bräuchte, ist also keine gute Idee.)
    - Ich habe noch einen Satz zu Maßnahmen gegen Replay attacks hinzugefügt (deleting duplicated ballots) geschrieben.
    - Das Problem mit Re-rendomization attakcs habe ich jetzt erstmal außern vor gelassen. (Ich könnte aber auch dazu noch ein zwei Sätze in der Fußnote schreiben ;-))

- S.22: In Algorithmus 2.1: Was macht VA.Setup(sk)? Das wirkt irgendwie doppelt gemoppelt mit S.Gen(1^\eta), auch wenn es wohl mehr Sinn macht, dass die VA die Schlüssel erzeugt.
    - Bis jetzt war $VA.Setup(sk)$ dazu da den generierten $sk$ an die $VA$ weiterzugeben.
    - Prinzipiell kann ich den $VA.Setup$ algorithmus aber auch so umgestalten, dass dieser das Key-pair generiert und dann den entsprechenden $pk$ auf dem $PBB$ published. Wäre das sinnvoll? (Das habe ich noch nicht gemacht, weil ich dann nicht mehr alle setup paramter in einem eintrag auf dem $PBB$ hätte und dementsprechend auch die grafiken sowie den voting und tallying algorithmus nochmal ändern müsste. Aber wenn das in deinem Sinne wäre, mache ich das noch)

- S.27: Ich würde die Multiplikation auf C einmal allgemein definieren. So wie du es schreibst, liest es sich als könnten wir nur ciphertexte multiplizieren.
    - Ja, das ergibt Sinn, ich habe die Definition entsprechend geändert.

- S.28:In Fußnote 2: Ich denke du meinst etwas anderes als du schreibst. Der Choicespace dürfte keine Teilmenge von G sein, oder?
    - Ja, im Allgemeinen ist der choice space $C$ keine Teilmenge von $G$. Ich habe die Fußnote entsprechend geändert.

- S.28: In der unteren Gleichung stimmt die vorletzte Umformung so nicht. Du hast da ja noch den Logarithmus-Schritt, der hier nicht mehr wirklich hervorgeht. Den solltest du vermutlich notationell mit reinpacken.
    - Ja, mein Fehler, ich habe es korrigiert.

- Kapitel 4: Ich habe im Prinzip nichts dagegen, dass du nicht näher auf Weierstrass-Kurven eingehst. Denk aber dran, dass nur die ElGamal-Kurve (Curve25519 bzw. je nach Zeit noch soetwas wie Bandersnatch) eine Montgomery-Kurve sein wird, die SNARK-Kurve (BN254 oder BLS-312-81) aber keine Montgomerykurve ist. Je nachdem, wie viel du zu dem Thema später erzählst, kann es sein, dass du dir das Leben etwas schwer machst, wenn du Kapitel 4 auf Montgomery-Kurven einschränkst.
    - Daran habe ich selbstverständlich nicht gedacht. ;-)
    Ich werde das dann entsprechend high-levelig behandeln bei Groth16. 
    - Solange ich kein konkretes Beispiel durchrechnen möchte, ist es doch eigentlich egal, was für eine Elliptische Kurve die Basis ist, oder? (Das wäre doch nur relevant, wenn ich tatsächlich das group law berechnen müsste, oder?)

- Kapitel 4: Sind 4.4.2, 4.4.3, 4.4.4 und 4.4.6 nicht eher Sätze als Definitionen? Ich denke man müsste beweisen, dass xDbl(x(P))=x(P²) gilt (und analog für xAdd, die MontgomeryLadder und die y-recovery), oder zumindest den entsprechenden Beweis zitieren. 
    - Naja, Ich "definiere" die Pseudooperationen, die Montgomery Ladder, etc. von daher ist das als Definition denke ich in Ordnung. Trotzdem hast du natürlich Recht, dass ich die in der Definition behaupteten Äquivalenzen zeigen müsste.
    - Ich habe mal in dem Paper guguckt, an dem ich mich füür die Sektion orientiert habe. Da haben die Autoren auch nur auf Montgoemrey selbst verwiesen für die Pseudooperations. (Soll ich das auch machen?)
    - Für den Korrektkheitsbeweis der Montgomery Ladder habe ich jetzt das Übersichtspaper zitiert, an dem ich ich orientiert habe. Da ist einer gegeben.
    - Für den Korrektheitsbeweis des okeya-Sakurai Algorithmus habe ich jetzt auf das original-Paper verwiesen. Bei dem allgemeinen Recovery-Algorithmus habe ich glaube ich ganz gut argumentiert, warum wir die Edge-Cases des Okeya-Sakurai Y-Recovery algorithmus abfangen und korrekt behandeln. Sollte ich da noch was ergänzen?