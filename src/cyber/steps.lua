return {
	WrapInFunction = require("cyber.steps.WrapInFunction");
	SplitStrings   = require("cyber.steps.SplitStrings");
	Vmify          = require("cyber.steps.Vmify");
	ConstantArray  = require("cyber.steps.ConstantArray");
	ProxifyLocals  = require("cyber.steps.ProxifyLocals");
	AntiTamper  = require("cyber.steps.AntiTamper");
	EncryptStrings = require("cyber.steps.EncryptStrings");
	NumbersToExpressions = require("cyber.steps.NumbersToExpressions");
	AddVararg 	= require("cyber.steps.AddVararg");
}