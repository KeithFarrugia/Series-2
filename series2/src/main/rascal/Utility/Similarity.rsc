module Utility::Similarity

import Node;
import List;

public num calculateSimilarity(node tree1, node tree2) {
	//Similarity = 2 x S / (2 x S + L + R)
	
	list[node] tree1Nodes = [];

    visit (tree1) {
		case node x: {
			tree1Nodes += x;
		}
	}

	list[node] tree2Nodes = [];
	
	visit (tree2) {
		case node x: {
			tree2Nodes += x;
		}
	}
	
	num s = size(tree1Nodes & tree2Nodes);
	num l = size(tree1Nodes - tree2Nodes);
	num r = size(tree2Nodes - tree1Nodes); 
		
    // If they are the same l and r = 0 and similarity = 1
    // If they are different it returns the similarity score between 0 and 1 (percentage of similarity)
	num similarity = (2 * s) / (2 * s + l + r); 

	return similarity;
}