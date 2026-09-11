################################################################################
#This is an internally genertaed by spyglass to populate Waiver Info for Reports
#Note:Spyglass does not support any perl routine like "spyDecompileWaiverInfo"
#     The routine is purely for internal usage of spyglass
################################################################################


use SpyGlass;

spyClearWaiverHashInPerl(0);

spyComputeWaivedViolCount("totalWaivedViolationCount"=>'15',
                          "totalGeneratedCount"=>'0',
                          "totalReportCount"=>'0'
                         );

spyDecompileWaiverInfo("waive_cmd_id"=>'1',
                       "waiverCmd"=>'q%waive -rule "Ac_unsync01"%',
                       "-rule"=>'"Ac_unsync01"',
                       "violations_waived"=>'8 18 20',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"cdc.sgdc"',
                       "waiverline"=>'28'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'2',
                       "waiverCmd"=>'q%waive -rule "Ac_unsync02"%',
                       "-rule"=>'"Ac_unsync02"',
                       "violations_waived"=>'10 11 14 16 22 23 25 26',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"cdc.sgdc"',
                       "waiverline"=>'29'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'3',
                       "waiverCmd"=>'q%waive -rule "Ar_unsync01"%',
                       "-rule"=>'"Ar_unsync01"',
                       "violations_waived"=>'47 48',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"cdc.sgdc"',
                       "waiverline"=>'30'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'4',
                       "waiverCmd"=>'q%waive -rule "Setup_port01"%',
                       "-rule"=>'"Setup_port01"',
                       "violations_waived"=>'65 67',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"cdc.sgdc"',
                       "waiverline"=>'31'
                      );

spyWaiversDataCount("totalWaivers"=>'4',
"totalWaiversApplied"=>'4',
"totalWaiversWithRegExp"=>'0',
"totalWaiversWithRuleSpecified"=>'4',
"totalWaiversWithIpSpecified"=>'0',
"totalWaiversWithFileLine"=>'0',
                         );

spyProhibitWaiverRules(                         );

spySetWaivedViolationNumberHash("");

1;
