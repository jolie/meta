/*
 * Copyright (C) 2021 Fabrizio Montesi <famontesi@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

type Identifier: string // add fancy regex for identifiers here

// ------------
// Syntax nodes
// ------------

type Module {
	imports*: ImportStatement
	types*: TypeDefinition
	services*: Service
}

type ParsingContext {
	source: string //< format is system-dependent
	sourceName: string // TODO: This is probably just a method in Java.. how do we model this? Should we just remove it here?
	line: int // we should extend this to a region for precise highlighting and error messages: [[col, line], [col,line]]
}

// TODO: I'm assuming all syntax nodes can be documented here, for simplicity. we might want to be more precise.
type SyntaxNodeBase {
	context: ParsingContext
	documentation?: string
}

// Super nifty trick to simulate sealed classes. :-)
// Use a base type, extend it with the cases, and then define a choice type for the cases that you wanna consider.
type ImportStatementBase {
	modulePath+: string // this should be a refined type
}

// ext means "extended with", or "merge"
type ImportStatementSomeSymbols: ImportStatementBase ext {
	symbols+ {
		name: string
		alias?: string
	}
}

type ImportStatementAllSymbols: ImportStatementBase ext {
	all: void
}

type ImportStatement:
	ImportStatementSomeSymbols
	| ImportStatementAllSymbols

/*
Note by FM: On intersection types to make sealed type cases.

I tried using intersections, as follows

type SyntaxNode open {
	context: ParsingContext
	documentation?: string
}

type Definition: SyntaxNode & {
	name: string
	body: JolieSyntaxNode
}

but since this requires making SyntaxNode an open record, anything
could potentially extend it regardless of any sensical attempt at sealed types
anyway (because we interpret types as sets of values and values are not accompanied
by type information at runtime, they are fully erased).
*/

/*
Note by FM: abstract types that cannot be instantiated do not 
make much sense in Jolie, because values do not have runtime type information.
*/

type TypeDefinition {
	id: Identifier
	expression: TypeExpression
}

/* Note by FM:
It's somewhat difficult to make sure that these unions are disjoint...
Possible solutions:
	- Introduce a disjoint union operator that requires the programmer to provide disjoint types.
	- Introduce sum types (which basically add nodes to distinguish cases by themselves)

Below, I use sum types (tagged unions).
The idea of a tagged union is that it injects a field
with the name of the type itself and type "void", which hopefully does not introduce problems.
Otherwise, we leave it to the programmer to use union manually.
*/
type TypeExpression:
	ReferenceType //< reference to another type
	+ RecordType
	+ UnionTypeExpression
	+ MergeTypeExpression

type RecordType {
	basicType: BasicType
	fields = map<string, TypeExpression> // not sure how to write this yet. we probably wanna be inspired by typescript's dictionaries.
}

type BinaryTypeExpression {
	left: TypeExpression
	right: TypeExpression
}

/*
Note by FM: here comes the disjointness problem again, see the following two types.
They are not disjoint, but they should be. Hence we use sum types in TypeExpression.
*/
type UnionTypeExpression: BinaryTypeExpression
type MergeTypeExpression: BinaryTypeExpression

type Service: SyntaxNode ext {
	inputPorts*: InputPort
	outputPorts*: OutputPort
	embedStatements*: EmbedStatements
	definitions: map<string, Behaviour>
	main: Behaviour
}

type Behaviour:
	WhileLoop
	+ ForLoop

type WhileLoop: SyntaxNode & {
	condition: Condition
	body: SyntaxNode
}

// ----------
// Conditions
// ----------

type Condition extends SyntaxNode

// -----------
// Expressions
// -----------

// --------------
// Variable Paths
// --------------

// TODO: not sure about the name "elements". In the Java impl it's unnamed.
type VariablePath {
	elements+ {
		name: Expression
		index: Expression
	}
}

// ----------
// Conditions
// ----------

// TODO: need tagged unions? AndCondition and OrCondition are basically the same..
// Here the same trick used for SyntaxNode doesn't work because we cannot distinguish
// the different cases from the different structures (they are not all different).
// Strong suggestion that we need sum types.

type Condition: open void

type AndCondition: Condition & {
	children*: Condition
}

type OrCondition: Condition & {
	children*: Condition
}

// -----
// Types
// -----

// TODO: Should we express here that it is an ImportableSymbol? See Java implementation.
type TypeDefinition {
	name: string
}
