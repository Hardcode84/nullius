import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from audit_organic_recovery import audit

class OrganicRecoveryTest(unittest.TestCase):
    def recipe(self, inputs, outputs):
        return {"ingredients": [{"type":"item","name":n,"amount":1} for n in inputs],
                "results": [{"type":"item","name":n,"amount":1} for n in outputs]}

    def test_downstream_boxed_and_secondary_recovery(self):
        data={"recipe": {
            "box":self.recipe(["gear"],["gear-box"]),
            "machine":self.recipe(["gear-box"],["machine","scrap"]),
            "recycle":self.recipe(["machine"],["iron"]),
            "scrap":self.recipe(["scrap"],["iron"]),
        }}
        result=audit(data,{"components":["gear"],"protected":["iron"]})
        self.assertEqual({r["recipe"] for r in result["metal_recovery"]},{"recycle","scrap"})

    def test_mineral_feed_and_zero_yield(self):
        recipe=self.recipe(["gear"],["iron"])
        recipe["results"][0]["independent_probability"]=0
        data={"recipe":{"zero":recipe,"smelting":self.recipe(["gear","ore"],["iron"])}}
        self.assertEqual(audit(data,{"components":["gear"],"protected":["ore","iron"]})["metal_recovery"],[])
